import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score tier.
    final class RiskScoreTierView {
        var codeText: String
        var labelText: String
        var visitMinutesText: String
        var checksum: String
        var refills: String
        var statusLabel: String

        init(codeText: String, labelText: String, visitMinutesText: String, checksum: String, refills: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.visitMinutesText = visitMinutesText
            self.checksum = checksum
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreTierView(_ item: RiskScoreTier) -> RiskScoreTierView {
        return RiskScoreTierView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            visitMinutesText: String(item.visitMinutes),
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreTierViews(_ items: [RiskScoreTier]) -> [RiskScoreTierView] {
        var views: [RiskScoreTierView] = []
        for item in items {
            views.append(toRiskScoreTierView(item))
        }
        return views
    }

    static func sumRiskScoreTierView(_ view: RiskScoreTierView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedRefills)
    }
}
