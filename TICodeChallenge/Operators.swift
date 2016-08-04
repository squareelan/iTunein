//
//  Operators.swift
//  RxExample
//
//  Created by Krunoslav Zaher on 12/6/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
#if !RX_NO_MODULE
	import RxSwift
	import RxCocoa
#endif

import UIKit

// Two way binding operator between control property and variable, that's all it takes {

infix operator <-> {
}

func nonMarkedText(textInput: UITextInput) -> String? {
	let start = textInput.beginningOfDocument
	let end = textInput.endOfDocument

	guard let rangeAll = textInput.textRangeFromPosition(start, toPosition: end),
		text = textInput.textInRange(rangeAll) else {
			return nil
	}

	guard let markedTextRange = textInput.markedTextRange else {
		return text
	}

	guard let startRange = textInput.textRangeFromPosition(start, toPosition: markedTextRange.start),
		endRange = textInput.textRangeFromPosition(markedTextRange.end, toPosition: end) else {
			return text
	}

	return (textInput.textInRange(startRange) ?? "") + (textInput.textInRange(endRange) ?? "")
}

func <-> (textInput: RxTextInput, variable: Variable<String>) -> Disposable {
	let bindToUIDisposable = variable.asObservable()
		.bindTo(textInput.rx_text)
	let bindToVariable = textInput.rx_text
		.subscribe(onNext: { [weak textInput] n in
			guard let textInput = textInput else {
				return
			}

			let nonMarkedTextValue = nonMarkedText(textInput)

			/**
			In some cases `textInput.textRangeFromPosition(start, toPosition: end)` will return nil even though the underlying
			value is not nil. This appears to be an Apple bug. If it's not, and we are doing something wrong, please let us know.
			The can be reproed easily if replace bottom code with

			if nonMarkedTextValue != variable.value {
			variable.value = nonMarkedTextValue ?? ""
			}
			and you hit "Done" button on keyboard.
			*/
			if let nonMarkedTextValue = nonMarkedTextValue where nonMarkedTextValue != variable.value {
				variable.value = nonMarkedTextValue
			}
			}, onCompleted:  {
				bindToUIDisposable.dispose()
		})

	return StableCompositeDisposable.create(bindToUIDisposable, bindToVariable)
}

func <-> <T>(property: ControlProperty<T>, variable: Variable<T>) -> Disposable {

	var updating = false

	let bindToUIDisposable = variable.asObservable().filter({ _ in
		updating = !updating
		return updating
	}).bindTo(property)

	let bindToVariable = property.filter({ _ in
		updating = !updating
		return updating
	}).subscribe(onNext: { n in
		variable.value = n
		}, onCompleted:  {
			bindToUIDisposable.dispose()
	})

	return StableCompositeDisposable.create(bindToUIDisposable, bindToVariable)
}