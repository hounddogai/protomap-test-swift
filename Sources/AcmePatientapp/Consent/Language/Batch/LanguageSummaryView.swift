import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language summary.
    final class LanguageSummaryView {
        var codeText: String
        var title: String
        var cost: String
        var threshold: String
        var bed: String
        var checksum: String
        var notes: String
        var channelText: String
        var quantityText: String
        var statusLabel: String

        init(codeText: String, title: String, cost: String, threshold: String, bed: String, checksum: String, notes: String, channelText: String, quantityText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.cost = cost
            self.threshold = threshold
            self.bed = bed
            self.checksum = checksum
            self.notes = notes
            self.channelText = channelText
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageSummaryView(_ item: LanguageSummary) -> LanguageSummaryView {
        return LanguageSummaryView(
            codeText: item.code,
            title: item.title,
            cost: String(format: "%.2f", item.cost),
            threshold: String(format: "%.2f", item.threshold),
            bed: item.bed,
            checksum: item.checksum,
            notes: item.notes,
            channelText: item.channel,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageSummaryViews(_ items: [LanguageSummary]) -> [LanguageSummaryView] {
        var views: [LanguageSummaryView] = []
        for item in items {
            views.append(toLanguageSummaryView(item))
        }
        return views
    }

    static func sumLanguageSummaryView(_ view: LanguageSummaryView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedCost + parsedThreshold + Double(parsedQuantity)
    }
}
