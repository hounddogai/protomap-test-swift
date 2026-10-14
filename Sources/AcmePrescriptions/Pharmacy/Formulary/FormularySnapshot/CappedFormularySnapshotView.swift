import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped formulary snapshot.
    final class CappedFormularySnapshotView {
        var code: String
        var nameText: String
        var cost: String
        var discount: String
        var externalRef: String
        var statusLabel: String

        init(code: String, nameText: String, cost: String, discount: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.cost = cost
            self.discount = discount
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toCappedFormularySnapshotView(_ item: CappedFormularySnapshot) -> CappedFormularySnapshotView {
        return CappedFormularySnapshotView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            cost: String(format: "%.2f", item.cost),
            discount: String(format: "%.2f", item.discount),
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedFormularySnapshotViews(_ items: [CappedFormularySnapshot]) -> [CappedFormularySnapshotView] {
        var views: [CappedFormularySnapshotView] = []
        for item in items {
            views.append(toCappedFormularySnapshotView(item))
        }
        return views
    }

    static func sumCappedFormularySnapshotView(_ view: CappedFormularySnapshotView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedCost + parsedDiscount
    }
}
