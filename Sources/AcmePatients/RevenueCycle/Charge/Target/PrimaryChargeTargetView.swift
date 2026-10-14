import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a primary charge target.
    final class PrimaryChargeTargetView {
        var code: String
        var nameText: String
        var visible: String
        var maximum: String
        var channelText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, nameText: String, visible: String, maximum: String, channelText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.visible = visible
            self.maximum = maximum
            self.channelText = channelText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryChargeTargetView(_ item: PrimaryChargeTarget) -> PrimaryChargeTargetView {
        return PrimaryChargeTargetView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            visible: "\(item.visible)",
            maximum: String(format: "%.2f", item.maximum),
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryChargeTargetViews(_ items: [PrimaryChargeTarget]) -> [PrimaryChargeTargetView] {
        var views: [PrimaryChargeTargetView] = []
        for item in items {
            views.append(toPrimaryChargeTargetView(item))
        }
        return views
    }

    static func sumPrimaryChargeTargetView(_ view: PrimaryChargeTargetView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
