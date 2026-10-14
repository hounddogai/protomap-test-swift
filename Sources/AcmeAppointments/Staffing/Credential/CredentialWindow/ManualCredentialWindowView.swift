import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual credential window.
    final class ManualCredentialWindowView {
        var code: String
        var name: String
        var category: String
        var batchSize: String
        var endsAt: String
        var pinned: String
        var statusLabel: String

        init(code: String, name: String, category: String, batchSize: String, endsAt: String, pinned: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.category = category
            self.batchSize = batchSize
            self.endsAt = endsAt
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toManualCredentialWindowView(_ item: ManualCredentialWindow) -> ManualCredentialWindowView {
        return ManualCredentialWindowView(
            code: item.code,
            name: item.name,
            category: item.category,
            batchSize: String(item.batchSize),
            endsAt: String(item.endsAt),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCredentialWindowViews(_ items: [ManualCredentialWindow]) -> [ManualCredentialWindowView] {
        var views: [ManualCredentialWindowView] = []
        for item in items {
            views.append(toManualCredentialWindowView(item))
        }
        return views
    }

    static func sumManualCredentialWindowView(_ view: ManualCredentialWindowView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedEndsAt)
    }
}
