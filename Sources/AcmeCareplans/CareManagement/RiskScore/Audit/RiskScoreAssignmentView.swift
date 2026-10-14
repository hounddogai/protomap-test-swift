import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score assignment.
    final class RiskScoreAssignmentView {
        var code: String
        var name: String
        var encounterID: String
        var description: String
        var localeText: String
        var ward: String
        var marginText: String
        var retries: String
        var externalRef: String
        var statusLabel: String

        init(code: String, name: String, encounterID: String, description: String, localeText: String, ward: String, marginText: String, retries: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.description = description
            self.localeText = localeText
            self.ward = ward
            self.marginText = marginText
            self.retries = retries
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreAssignmentView(_ item: RiskScoreAssignment) -> RiskScoreAssignmentView {
        return RiskScoreAssignmentView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            encounterID: item.encounterID,
            description: item.description,
            localeText: item.locale,
            ward: item.ward,
            marginText: String(format: "%.2f", item.margin),
            retries: String(item.retries),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreAssignmentViews(_ items: [RiskScoreAssignment]) -> [RiskScoreAssignmentView] {
        var views: [RiskScoreAssignmentView] = []
        for item in items {
            views.append(toRiskScoreAssignmentView(item))
        }
        return views
    }

    static func sumRiskScoreAssignmentView(_ view: RiskScoreAssignmentView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedMargin + Double(parsedRetries)
    }
}
