//
//  TIBrowseViewModel.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

struct TIBrowseViewModel {

	// Core data
	let browseItem: TIBrowse

	var title: String?
	var numberOfSections: Int {

		// if outline item have children, use it for a row.
		// parent outline item becomes section header.
		return browseItem.anyOutlineContainsChildren() ?
			browseItem.outlines.count : 1
	}


	func numberOfRows(for section: Int) -> Int {
		if let children = browseItem.outlines[section].children {
			return children.count
		}
		else {
			if !browseItem.anyOutlineContainsChildren() {
				return browseItem.outlines.count
			}
			return 1
		}
	}

	func sectionTitle(for section: Int) -> String? {
		if browseItem.outlines[section].children != nil {
			return browseItem.outlines[section].text
		}
		return nil
	}

	func outline(for section: Int, row: Int) -> TIOutline {
		if let children = browseItem.outlines[section].children {
			return children[row]
		}
		else {
			if !browseItem.anyOutlineContainsChildren() {
				return browseItem.outlines[row]
			}
			return browseItem.outlines[section]
		}

	}
}
