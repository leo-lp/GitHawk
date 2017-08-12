//
//  IssueViewFilesSectionController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 8/11/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation
import IGListKit

final class IssueViewFilesSectionController: ListSectionController {

    private let issueModel: IssueDetailsModel

    init(issueModel: IssueDetailsModel) {
        self.issueModel = issueModel
        super.init()
    }

    override func sizeForItem(at index: Int) -> CGSize {
        guard let width = collectionContext?.containerSize.width else { fatalError("Collection context must be set") }
        return CGSize(width: width, height: Styles.Sizes.labelEventHeight)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let cell = collectionContext?.dequeueReusableCell(of: IssueViewFilesCell.self, for: self, at: index)
            else { fatalError("Missing collection context") }
        return cell
    }

    override func didSelectItem(at index: Int) {
        collectionContext?.deselectItem(at: index, sectionController: self, animated: true)
    }

}
