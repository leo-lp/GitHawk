//
//  GithubClient+Issues.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/2/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit

extension GithubClient {

    enum IssueResultType {
        case error
        case success(IssueResult)
    }

    func fetch(
        owner: String,
        repo: String,
        number: Int,
        width: CGFloat,
        prependResult: IssueResult?,
        completion: @escaping (IssueResultType) -> ()
        ) {

        let query = IssueOrPullRequestQuery(
            owner: owner,
            repo: repo,
            number: number,
            pageSize: 100,
            before: prependResult?.minStartCursor
        )

        apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
            let repository = result?.data?.repository
            let issueOrPullRequest = repository?.issueOrPullRequest
            if let issueType: IssueType = issueOrPullRequest?.asIssue ?? issueOrPullRequest?.asPullRequest {
                DispatchQueue.global().async {

                    let status: IssueStatus = issueType.merged ? .merged : issueType.closableFields.closed ? .closed : .open
                    let mentionableUsers = repository?.mentionableUsers.autocompleteUsers ?? []

                    let rootComment = createCommentModel(
                        id: issueType.id,
                        commentFields: issueType.commentFields,
                        reactionFields: issueType.reactionFields,
                        width: width,
                        threadState: .single
                        )

                    let paging = issueType.headPaging
                    let newPage = IssueTimelinePage(
                        startCursor: paging.hasPreviousPage ? paging.startCursor : nil,
                        viewModels: issueType.timelineViewModels(width: width)
                    )

                    let issueResult = IssueResult(
                        subjectId: issueType.id,
                        pullRequest: issueType.pullRequest,
                        status: IssueStatusModel(status: status, pullRequest: issueType.pullRequest, locked: issueType.locked),
                        title: titleStringSizing(title: issueType.title, width: width),
                        labels: IssueLabelsModel(viewerCanUpdate: issueType.viewerCanUpdate, labels: issueType.labelableFields.issueLabelModels),
                        assignee: createAssigneeModel(assigneeFields: issueType.assigneeFields),
                        rootComment: rootComment,
                        reviewers: issueType.reviewRequestModel,
                        mentionableUsers: mentionableUsers,
                        timelinePages: [newPage] + (prependResult?.timelinePages ?? [])
                    )

                    DispatchQueue.main.async {
                        completion(.success(issueResult))
                    }
                }
            } else {
                completion(.error)
            }
            ShowErrorStatusBar(graphQLErrors: result?.errors, networkError: error)
        }
    }

    func react(
        subjectID: String,
        content: ReactionContent,
        isAdd: Bool,
        completion: @escaping (IssueCommentReactionViewModel?) -> ()
        ) {
        if isAdd {
            apollo.perform(mutation: AddReactionMutation(subjectId: subjectID, content: content)) { (result, error) in
                if let reactionFields = result?.data?.addReaction?.subject.fragments.reactionFields {
                    completion(createIssueReactions(reactions: reactionFields))
                } else {
                    completion(nil)
                }
                ShowErrorStatusBar(graphQLErrors: result?.errors, networkError: error)
            }
        } else {
            apollo.perform(mutation: RemoveReactionMutation(subjectId: subjectID, content: content)) { (result, error) in
                if let reactionFields = result?.data?.removeReaction?.subject.fragments.reactionFields {
                    completion(createIssueReactions(reactions: reactionFields))
                } else {
                    completion(nil)
                }
                ShowErrorStatusBar(graphQLErrors: result?.errors, networkError: error)
            }
        }
    }

}
