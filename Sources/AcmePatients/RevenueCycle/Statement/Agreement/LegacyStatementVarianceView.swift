import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a legacy statement variance.
    final class LegacyStatementVarianceView {
        var code: String
        var label: String
        var phoneText: String
        var active: String
        var payerText: String
        var pinned: String
        var archivedText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, label: String, phoneText: String, active: String, payerText: String, pinned: String, archivedText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.phoneText = phoneText
            self.active = active
            self.payerText = payerText
            self.pinned = pinned
            self.archivedText = archivedText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyStatementVarianceView(_ item: LegacyStatementVariance) -> LegacyStatementVarianceView {
        return LegacyStatementVarianceView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            phoneText: Kit.Text.truncate(item.phone, limit: 80),
            active: "\(item.active)",
            payerText: Kit.Text.truncate(item.payer, limit: 120),
            pinned: "\(item.pinned)",
            archivedText: "\(item.archived)",
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyStatementVarianceViews(_ items: [LegacyStatementVariance]) -> [LegacyStatementVarianceView] {
        var views: [LegacyStatementVarianceView] = []
        for item in items {
            views.append(toLegacyStatementVarianceView(item))
        }
        return views
    }

    static func sumLegacyStatementVarianceView(_ view: LegacyStatementVarianceView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
