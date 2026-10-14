import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization template.
    final class AuthorizationTemplateView {
        var code: String
        var nameText: String
        var checksumText: String
        var floorValueText: String
        var refills: String
        var retries: String
        var patientRefText: String
        var graceDays: String
        var maximum: String
        var ownerID: String
        var amount: String
        var statusLabel: String

        init(code: String, nameText: String, checksumText: String, floorValueText: String, refills: String, retries: String, patientRefText: String, graceDays: String, maximum: String, ownerID: String, amount: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.checksumText = checksumText
            self.floorValueText = floorValueText
            self.refills = refills
            self.retries = retries
            self.patientRefText = patientRefText
            self.graceDays = graceDays
            self.maximum = maximum
            self.ownerID = ownerID
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationTemplateView(_ item: AuthorizationTemplate) -> AuthorizationTemplateView {
        return AuthorizationTemplateView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            checksumText: item.checksum,
            floorValueText: String(format: "%.2f", item.floorValue),
            refills: String(item.refills),
            retries: String(item.retries),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 40),
            graceDays: String(item.graceDays),
            maximum: String(format: "%.2f", item.maximum),
            ownerID: item.ownerID,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationTemplateViews(_ items: [AuthorizationTemplate]) -> [AuthorizationTemplateView] {
        var views: [AuthorizationTemplateView] = []
        for item in items {
            views.append(toAuthorizationTemplateView(item))
        }
        return views
    }

    static func sumAuthorizationTemplateView(_ view: AuthorizationTemplateView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedFloorValue + Double(parsedRefills) + Double(parsedRetries)
    }
}
