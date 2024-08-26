//
//  Stack.swift
//  AlienInvaders
//
//  Created by Doug on 8/26/24.
//

import Foundation

struct Stack<T> {
    private var stack: [T] = []
    
    mutating func push(_ elem: T) {
        stack.append(elem)
    }
    
    @discardableResult
    mutating func pop() -> T? {
        return stack.popLast()
    }
    
    func peek() -> T? {
        return stack.last
    }
 
    var isEmpty: Bool {
        return stack.isEmpty
    }

    var count: Int {
        return stack.count
    }
}

class ListHolder<T> {
    var list: [T] = []
    
    func append(_ elem: T) {
        list.append(elem)
    }
}
