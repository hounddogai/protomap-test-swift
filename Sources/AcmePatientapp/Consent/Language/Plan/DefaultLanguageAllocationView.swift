import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default language allocation.
    final class DefaultLanguageAllocationView {
        var codeText: String
        var name: String
        var limit: String
        var sequenceText: String
        var createdAt: String
        var statusLabel: String

        init(codeText: String, name: String, limit: String, sequenceText: String, createdAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.limit = limit
            self.sequenceText = sequenceText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultLanguageAllocationView(_ item: DefaultLanguageAllocation) -> DefaultLanguageAllocationView {
        return DefaultLanguageAllocationView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            limit: String(item.limit),
            sequenceText: String(item.sequence),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultLanguageAllocationViews(_ items: [DefaultLanguageAllocation]) -> [DefaultLanguageAllocationView] {
        var views: [DefaultLanguageAllocationView] = []
        for item in items {
            views.append(toDefaultLanguageAllocationView(item))
        }
        return views
    }

    static func sumDefaultLanguageAllocationView(_ view: DefaultLanguageAllocationView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedLimit) + Double(parsedSequence) + Double(parsedCreatedAt)
    }
}
