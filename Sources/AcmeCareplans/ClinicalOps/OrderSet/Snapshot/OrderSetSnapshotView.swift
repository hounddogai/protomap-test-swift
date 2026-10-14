import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set snapshot.
    final class OrderSetSnapshotView {
        var code: String
        var name: String
        var activeText: String
        var pinnedText: String
        var quantity: String
        var acuity: String
        var statusLabel: String

        init(code: String, name: String, activeText: String, pinnedText: String, quantity: String, acuity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.activeText = activeText
            self.pinnedText = pinnedText
            self.quantity = quantity
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetSnapshotView(_ item: OrderSetSnapshot) -> OrderSetSnapshotView {
        return OrderSetSnapshotView(
            code: item.code,
            name: item.name,
            activeText: "\(item.active)",
            pinnedText: "\(item.pinned)",
            quantity: String(item.quantity),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetSnapshotViews(_ items: [OrderSetSnapshot]) -> [OrderSetSnapshotView] {
        var views: [OrderSetSnapshotView] = []
        for item in items {
            views.append(toOrderSetSnapshotView(item))
        }
        return views
    }

    static func sumOrderSetSnapshotView(_ view: OrderSetSnapshotView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedQuantity) + Double(parsedAcuity)
    }
}
