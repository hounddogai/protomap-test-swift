import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional witness draft.
    final class RegionalWitnessDraftView {
        var code: String
        var labelText: String
        var endsAt: String
        var cost: String
        var batchSize: String
        var revisionText: String
        var limitText: String
        var statusLabel: String

        init(code: String, labelText: String, endsAt: String, cost: String, batchSize: String, revisionText: String, limitText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.endsAt = endsAt
            self.cost = cost
            self.batchSize = batchSize
            self.revisionText = revisionText
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalWitnessDraftView(_ item: RegionalWitnessDraft) -> RegionalWitnessDraftView {
        return RegionalWitnessDraftView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            endsAt: String(item.endsAt),
            cost: String(format: "%.2f", item.cost),
            batchSize: String(item.batchSize),
            revisionText: String(item.revision),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalWitnessDraftViews(_ items: [RegionalWitnessDraft]) -> [RegionalWitnessDraftView] {
        var views: [RegionalWitnessDraftView] = []
        for item in items {
            views.append(toRegionalWitnessDraftView(item))
        }
        return views
    }

    static func sumRegionalWitnessDraftView(_ view: RegionalWitnessDraftView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedEndsAt) + parsedCost + Double(parsedBatchSize)
    }
}
