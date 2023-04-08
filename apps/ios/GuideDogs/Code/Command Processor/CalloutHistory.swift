//
//  CalloutHistory.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

/// The delegate protocol for CalloutHistory that receives notifications when the history is modified.
protocol CalloutHistoryDelegate: AnyObject {
    
    /// Called when a callout is inserted into the history.
    func onCalloutInserted(_ callout: CalloutProtocol)
    
    /// Called when a callout is removed from the history.
    func onCalloutRemoved(_ callout: CalloutProtocol)
    
    /// Called when the callout history is cleared.
    func onHistoryCleared()
}


/// The CalloutHistory class is responsible for keeping track of a history of callouts.
///
/// The CalloutHistory class is implemented using a BoundedStack data structure to ensure
/// that the number of callouts in the history is bounded to a maximum value.
class CalloutHistory {
    
    /// The delegate that receives notifications when the history is modified.
    weak var delegate: CalloutHistoryDelegate? {
        didSet {
            /// Make sure that we call `onCalloutInserted` for every callout once. This
            /// ensures that if a callout is inserted before the delegate is attached,
            /// the delegate will still be informed of it.
            for callout in calloutStack.elements {
                delegate?.onCalloutInserted(callout)
            }
        }
    }
    
    /// The maximum number of callouts that can be stored in the history.
    var maxItems: UInt {
        return calloutStack.bound
    }
    
    /// An array of callouts in the history.
    public var callouts: [CalloutProtocol] {
        return calloutStack.elements
    }
    
    /// The internal stack that stores the callouts.
    private var calloutStack: BoundedStack<CalloutProtocol>
    
    /// Initializes the callout history with a maximum number of callouts that can be stored.
    /// - Parameter maxItems: The maximum number of callouts that can be stored in the history. Default is 10.
    init(maxItems: UInt = 10) {
        calloutStack = BoundedStack<CalloutProtocol>(bound: maxItems)
    }
    
    /// Inserts a callout into the history and notifies the delegate.
    /// - Parameter callout: The callout to insert into the history.
    func insert(_ callout: CalloutProtocol) {
        guard callout.includeInHistory else {
            return
        }
        
        calloutStack.push(callout)
        delegate?.onCalloutInserted(callout)
    }
    
    /// Inserts an array of callouts into the history and notifies the delegate.
    /// - Parameter array: The array of callouts to insert into the history.
    func insert<T: CalloutProtocol>(contentsOf array: [T]) {
        let callouts = array.filter({ $0.includeInHistory })
        
        guard callouts.count > 0 else {
            return
        }
        
        calloutStack.push(contentsOf: callouts)
        
        for callout in callouts {
            delegate?.onCalloutInserted(callout)
        }
    }
    
    /// Returns the index of a callout in the history if it is visible (i.e., if it has the includeInHistory property set to true).
    /// - Parameter callout: The callout to search for in the history.
    /// - Returns: The index of the callout in the history if it is visible, otherwise nil.
    func visibleIndex(of callout: CalloutProtocol) -> Int? {
        guard callout.includeInHistory else {
            return nil
        }
        
        return calloutStack.elements.filter({$0.includeInHistory}).reversed().firstIndex(where: { $0.equals(rhs: callout) })
    }
    
    /// Removes callouts from the callout history.
    /// - Parameter predicate: The predicate used to determine which callouts to remove.
    func remove(where predicate: (CalloutProtocol) -> Bool) {
        for removedItem in calloutStack.remove(where: predicate) {
            delegate?.onCalloutRemoved(removedItem)
        }
    }
    
    /// Clears the history by removing all callouts from the calloutStack.
    ///
    /// Notifies the delegate by calling onHistoryCleared().
    func clear() {
        calloutStack.clear()
        delegate?.onHistoryCleared()
    }
}
