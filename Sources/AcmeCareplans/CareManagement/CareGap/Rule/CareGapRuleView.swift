import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap rule.
    final class CareGapRuleView {
        var code: String
        var nameText: String
        var quantity: String
        var version: String
        var checksumText: String
        var discount: String
        var bed: String
        var statusLabel: String

        init(code: String, nameText: String, quantity: String, version: String, checksumText: String, discount: String, bed: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.quantity = quantity
            self.version = version
            self.checksumText = checksumText
            self.discount = discount
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapRuleView(_ item: CareGapRule) -> CareGapRuleView {
        return CareGapRuleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            quantity: String(item.quantity),
            version: String(item.version),
            checksumText: item.checksum,
            discount: String(format: "%.2f", item.discount),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapRuleViews(_ items: [CareGapRule]) -> [CareGapRuleView] {
        var views: [CareGapRuleView] = []
        for item in items {
            views.append(toCareGapRuleView(item))
        }
        return views
    }

    static func sumCareGapRuleView(_ view: CareGapRuleView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedQuantity) + Double(parsedVersion) + parsedDiscount
    }
}
