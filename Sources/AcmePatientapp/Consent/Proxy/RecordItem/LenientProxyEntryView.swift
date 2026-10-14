import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient proxy entry.
    final class LenientProxyEntryView {
        var code: String
        var label: String
        var summaryText: String
        var dosageMg: String
        var budgetText: String
        var minimum: String
        var statusLabel: String

        init(code: String, label: String, summaryText: String, dosageMg: String, budgetText: String, minimum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.summaryText = summaryText
            self.dosageMg = dosageMg
            self.budgetText = budgetText
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toLenientProxyEntryView(_ item: LenientProxyEntry) -> LenientProxyEntryView {
        return LenientProxyEntryView(
            code: item.code,
            label: item.label,
            summaryText: item.summary,
            dosageMg: String(format: "%.2f", item.dosageMg),
            budgetText: String(format: "%.2f", item.budget),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientProxyEntryViews(_ items: [LenientProxyEntry]) -> [LenientProxyEntryView] {
        var views: [LenientProxyEntryView] = []
        for item in items {
            views.append(toLenientProxyEntryView(item))
        }
        return views
    }

    static func sumLenientProxyEntryView(_ view: LenientProxyEntryView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedDosageMg + parsedBudget + parsedMinimum
    }
}
