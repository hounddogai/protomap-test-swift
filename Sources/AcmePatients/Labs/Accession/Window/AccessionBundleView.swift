import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession bundle.
    final class AccessionBundleView {
        var codeText: String
        var label: String
        var ward: String
        var archivedText: String
        var bed: String
        var amount: String
        var statusLabel: String

        init(codeText: String, label: String, ward: String, archivedText: String, bed: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ward = ward
            self.archivedText = archivedText
            self.bed = bed
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionBundleView(_ item: AccessionBundle) -> AccessionBundleView {
        return AccessionBundleView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            ward: item.ward,
            archivedText: "\(item.archived)",
            bed: item.bed,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionBundleViews(_ items: [AccessionBundle]) -> [AccessionBundleView] {
        var views: [AccessionBundleView] = []
        for item in items {
            views.append(toAccessionBundleView(item))
        }
        return views
    }

    static func sumAccessionBundleView(_ view: AccessionBundleView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
