import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a global consent form batch.
    final class GlobalConsentFormBatchView {
        var code: String
        var name: String
        var minimumText: String
        var segment: String
        var notes: String
        var copay: String
        var budgetText: String
        var region: String
        var startsAt: String
        var retries: String
        var source: String
        var statusLabel: String

        init(code: String, name: String, minimumText: String, segment: String, notes: String, copay: String, budgetText: String, region: String, startsAt: String, retries: String, source: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.minimumText = minimumText
            self.segment = segment
            self.notes = notes
            self.copay = copay
            self.budgetText = budgetText
            self.region = region
            self.startsAt = startsAt
            self.retries = retries
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalConsentFormBatchView(_ item: GlobalConsentFormBatch) -> GlobalConsentFormBatchView {
        return GlobalConsentFormBatchView(
            code: item.code,
            name: item.name,
            minimumText: String(format: "%.2f", item.minimum),
            segment: item.segment,
            notes: item.notes,
            copay: String(format: "%.2f", item.copay),
            budgetText: String(format: "%.2f", item.budget),
            region: item.region,
            startsAt: String(item.startsAt),
            retries: String(item.retries),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalConsentFormBatchViews(_ items: [GlobalConsentFormBatch]) -> [GlobalConsentFormBatchView] {
        var views: [GlobalConsentFormBatchView] = []
        for item in items {
            views.append(toGlobalConsentFormBatchView(item))
        }
        return views
    }

    static func sumGlobalConsentFormBatchView(_ view: GlobalConsentFormBatchView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedMinimum + parsedCopay + parsedBudget
    }
}
