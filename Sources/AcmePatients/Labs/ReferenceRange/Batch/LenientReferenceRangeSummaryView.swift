import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a lenient reference range summary.
    final class LenientReferenceRangeSummaryView {
        var code: String
        var label: String
        var endsAt: String
        var channel: String
        var limitText: String
        var ceiling: String
        var marginText: String
        var dosageMg: String
        var minimum: String
        var budget: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, label: String, endsAt: String, channel: String, limitText: String, ceiling: String, marginText: String, dosageMg: String, minimum: String, budget: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.channel = channel
            self.limitText = limitText
            self.ceiling = ceiling
            self.marginText = marginText
            self.dosageMg = dosageMg
            self.minimum = minimum
            self.budget = budget
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toLenientReferenceRangeSummaryView(_ item: LenientReferenceRangeSummary) -> LenientReferenceRangeSummaryView {
        return LenientReferenceRangeSummaryView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 80),
            endsAt: String(item.endsAt),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            limitText: String(item.limit),
            ceiling: String(format: "%.2f", item.ceiling),
            marginText: String(format: "%.2f", item.margin),
            dosageMg: String(format: "%.2f", item.dosageMg),
            minimum: String(format: "%.2f", item.minimum),
            budget: String(format: "%.2f", item.budget),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientReferenceRangeSummaryViews(_ items: [LenientReferenceRangeSummary]) -> [LenientReferenceRangeSummaryView] {
        var views: [LenientReferenceRangeSummaryView] = []
        for item in items {
            views.append(toLenientReferenceRangeSummaryView(item))
        }
        return views
    }

    static func sumLenientReferenceRangeSummaryView(_ view: LenientReferenceRangeSummaryView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedLimit) + parsedCeiling
    }
}
