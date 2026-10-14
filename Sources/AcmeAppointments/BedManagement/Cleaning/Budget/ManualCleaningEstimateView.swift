import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual cleaning estimate.
    final class ManualCleaningEstimateView {
        var code: String
        var name: String
        var refillsText: String
        var contactEmail: String
        var batchSize: String
        var notes: String
        var statusLabel: String

        init(code: String, name: String, refillsText: String, contactEmail: String, batchSize: String, notes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.refillsText = refillsText
            self.contactEmail = contactEmail
            self.batchSize = batchSize
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toManualCleaningEstimateView(_ item: ManualCleaningEstimate) -> ManualCleaningEstimateView {
        return ManualCleaningEstimateView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            refillsText: String(item.refills),
            contactEmail: item.contactEmail,
            batchSize: String(item.batchSize),
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCleaningEstimateViews(_ items: [ManualCleaningEstimate]) -> [ManualCleaningEstimateView] {
        var views: [ManualCleaningEstimateView] = []
        for item in items {
            views.append(toManualCleaningEstimateView(item))
        }
        return views
    }

    static func sumManualCleaningEstimateView(_ view: ManualCleaningEstimateView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedRefills) + Double(parsedBatchSize)
    }
}
