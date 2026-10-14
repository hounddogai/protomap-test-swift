import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization assignment.
    final class AuthorizationAssignmentView {
        var code: String
        var name: String
        var minimum: String
        var ceilingText: String
        var copayText: String
        var ratio: String
        var retries: String
        var clinicianID: String
        var facility: String
        var procedureCode: String
        var limitText: String
        var statusLabel: String

        init(code: String, name: String, minimum: String, ceilingText: String, copayText: String, ratio: String, retries: String, clinicianID: String, facility: String, procedureCode: String, limitText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.ceilingText = ceilingText
            self.copayText = copayText
            self.ratio = ratio
            self.retries = retries
            self.clinicianID = clinicianID
            self.facility = facility
            self.procedureCode = procedureCode
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationAssignmentView(_ item: AuthorizationAssignment) -> AuthorizationAssignmentView {
        return AuthorizationAssignmentView(
            code: item.code,
            name: item.name,
            minimum: String(format: "%.2f", item.minimum),
            ceilingText: String(format: "%.2f", item.ceiling),
            copayText: String(format: "%.2f", item.copay),
            ratio: String(format: "%.2f", item.ratio),
            retries: String(item.retries),
            clinicianID: item.clinicianID,
            facility: item.facility,
            procedureCode: item.procedureCode,
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationAssignmentViews(_ items: [AuthorizationAssignment]) -> [AuthorizationAssignmentView] {
        var views: [AuthorizationAssignmentView] = []
        for item in items {
            views.append(toAuthorizationAssignmentView(item))
        }
        return views
    }

    static func sumAuthorizationAssignmentView(_ view: AuthorizationAssignmentView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedMinimum + parsedCeiling + parsedCopay
    }
}
