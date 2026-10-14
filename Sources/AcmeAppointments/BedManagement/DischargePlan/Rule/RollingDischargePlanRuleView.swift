import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling discharge plan rule.
    final class RollingDischargePlanRuleView {
        var codeText: String
        var name: String
        var specialtyText: String
        var channel: String
        var expiresAtText: String
        var updatedAt: String
        var checksum: String
        var notes: String
        var label: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, name: String, specialtyText: String, channel: String, expiresAtText: String, updatedAt: String, checksum: String, notes: String, label: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.specialtyText = specialtyText
            self.channel = channel
            self.expiresAtText = expiresAtText
            self.updatedAt = updatedAt
            self.checksum = checksum
            self.notes = notes
            self.label = label
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDischargePlanRuleView(_ item: RollingDischargePlanRule) -> RollingDischargePlanRuleView {
        return RollingDischargePlanRuleView(
            codeText: item.code,
            name: item.name,
            specialtyText: item.specialty,
            channel: item.channel,
            expiresAtText: String(item.expiresAt),
            updatedAt: String(item.updatedAt),
            checksum: item.checksum,
            notes: item.notes,
            label: item.label,
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDischargePlanRuleViews(_ items: [RollingDischargePlanRule]) -> [RollingDischargePlanRuleView] {
        var views: [RollingDischargePlanRuleView] = []
        for item in items {
            views.append(toRollingDischargePlanRuleView(item))
        }
        return views
    }

    static func sumRollingDischargePlanRuleView(_ view: RollingDischargePlanRuleView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedUpdatedAt) + parsedFloorValue
    }
}
