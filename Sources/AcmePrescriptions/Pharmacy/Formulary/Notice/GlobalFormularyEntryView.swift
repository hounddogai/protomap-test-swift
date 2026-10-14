import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a global formulary entry.
    final class GlobalFormularyEntryView {
        var code: String
        var name: String
        var discountText: String
        var revisionText: String
        var payerText: String
        var rate: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, name: String, discountText: String, revisionText: String, payerText: String, rate: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.discountText = discountText
            self.revisionText = revisionText
            self.payerText = payerText
            self.rate = rate
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalFormularyEntryView(_ item: GlobalFormularyEntry) -> GlobalFormularyEntryView {
        return GlobalFormularyEntryView(
            code: item.code,
            name: item.name,
            discountText: String(format: "%.2f", item.discount),
            revisionText: String(item.revision),
            payerText: item.payer,
            rate: String(format: "%.2f", item.rate),
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalFormularyEntryViews(_ items: [GlobalFormularyEntry]) -> [GlobalFormularyEntryView] {
        var views: [GlobalFormularyEntryView] = []
        for item in items {
            views.append(toGlobalFormularyEntryView(item))
        }
        return views
    }

    static func sumGlobalFormularyEntryView(_ view: GlobalFormularyEntryView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedDiscount + Double(parsedRevision) + parsedRate
    }
}
