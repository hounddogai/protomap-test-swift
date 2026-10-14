import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive statement snapshot.
    final class AdaptiveStatementSnapshotView {
        var code: String
        var name: String
        var quantity: String
        var checksum: String
        var labelText: String
        var pinnedText: String
        var procedureCode: String
        var allergy: String
        var statusLabel: String

        init(code: String, name: String, quantity: String, checksum: String, labelText: String, pinnedText: String, procedureCode: String, allergy: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.checksum = checksum
            self.labelText = labelText
            self.pinnedText = pinnedText
            self.procedureCode = procedureCode
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveStatementSnapshotView(_ item: AdaptiveStatementSnapshot) -> AdaptiveStatementSnapshotView {
        return AdaptiveStatementSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 64),
            quantity: String(item.quantity),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 120),
            pinnedText: "\(item.pinned)",
            procedureCode: item.procedureCode,
            allergy: Kit.Text.truncate(item.allergy, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveStatementSnapshotViews(_ items: [AdaptiveStatementSnapshot]) -> [AdaptiveStatementSnapshotView] {
        var views: [AdaptiveStatementSnapshotView] = []
        for item in items {
            views.append(toAdaptiveStatementSnapshotView(item))
        }
        return views
    }

    static func sumAdaptiveStatementSnapshotView(_ view: AdaptiveStatementSnapshotView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
