import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling result policy.
    final class RollingResultPolicyView {
        var code: String
        var name: String
        var graceDays: String
        var quantity: String
        var archived: String
        var allergyText: String
        var externalRef: String
        var windowDays: String
        var unit: String
        var channel: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, name: String, graceDays: String, quantity: String, archived: String, allergyText: String, externalRef: String, windowDays: String, unit: String, channel: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.quantity = quantity
            self.archived = archived
            self.allergyText = allergyText
            self.externalRef = externalRef
            self.windowDays = windowDays
            self.unit = unit
            self.channel = channel
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toRollingResultPolicyView(_ item: RollingResultPolicy) -> RollingResultPolicyView {
        return RollingResultPolicyView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 64),
            graceDays: String(item.graceDays),
            quantity: String(item.quantity),
            archived: "\(item.archived)",
            allergyText: item.allergy,
            externalRef: item.externalRef,
            windowDays: String(item.windowDays),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            channel: Kit.Text.truncate(item.channel, limit: 64),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingResultPolicyViews(_ items: [RollingResultPolicy]) -> [RollingResultPolicyView] {
        var views: [RollingResultPolicyView] = []
        for item in items {
            views.append(toRollingResultPolicyView(item))
        }
        return views
    }

    static func sumRollingResultPolicyView(_ view: RollingResultPolicyView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedQuantity) + Double(parsedWindowDays)
    }
}
