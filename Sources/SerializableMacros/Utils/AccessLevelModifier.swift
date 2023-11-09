// Created 11/9/23
// swift-tools-version:5.0

import SwiftSyntax

enum AccessLevelModifier: String, Comparable, CaseIterable {
    case `private`, `fileprivate`, `internal`, `public`, `open`

    var keyword: Keyword {
        switch self {
        case .private:
            return .private
        case .fileprivate:
            return .fileprivate
        case .internal:
            return .internal
        case .public:
            return .public
        case .open:
            return .open
        }
    }
    
    func stringLiteral() -> String {
        return (self == .internal) ? "" : self.rawValue + " "
    }
    
    static func < (lhs: AccessLevelModifier, rhs: AccessLevelModifier) -> Bool {
        guard let lhs = Self.allCases.firstIndex(of: lhs),
              let rhs = Self.allCases.firstIndex(of: rhs)
        else {
            return false
        }
        return lhs < rhs
    }
}
