import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a default cleaning digest.
    final class DefaultCleaningDigestView {
        var code: String
        var title: String
        var diagnosisCode: String
        var copay: String
        var cost: String
        var label: String
        var quantity: String
        var summaryText: String
        var statusLabel: String

        init(code: String, title: String, diagnosisCode: String, copay: String, cost: String, label: String, quantity: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.copay = copay
            self.cost = cost
            self.label = label
            self.quantity = quantity
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCleaningDigestView(_ item: DefaultCleaningDigest) -> DefaultCleaningDigestView {
        return DefaultCleaningDigestView(
            code: item.code,
            title: item.title,
            diagnosisCode: item.diagnosisCode,
            copay: String(format: "%.2f", item.copay),
            cost: String(format: "%.2f", item.cost),
            label: item.label,
            quantity: String(item.quantity),
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCleaningDigestViews(_ items: [DefaultCleaningDigest]) -> [DefaultCleaningDigestView] {
        var views: [DefaultCleaningDigestView] = []
        for item in items {
            views.append(toDefaultCleaningDigestView(item))
        }
        return views
    }

    static func sumDefaultCleaningDigestView(_ view: DefaultCleaningDigestView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedCopay + parsedCost + Double(parsedQuantity)
    }
}
