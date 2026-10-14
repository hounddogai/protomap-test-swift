import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a primary result window.
    final class PrimaryResultWindowView {
        var code: String
        var label: String
        var source: String
        var diagnosisCode: String
        var active: String
        var visitMinutes: String
        var startsAt: String
        var statusLabel: String

        init(code: String, label: String, source: String, diagnosisCode: String, active: String, visitMinutes: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.source = source
            self.diagnosisCode = diagnosisCode
            self.active = active
            self.visitMinutes = visitMinutes
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryResultWindowView(_ item: PrimaryResultWindow) -> PrimaryResultWindowView {
        return PrimaryResultWindowView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            source: item.source,
            diagnosisCode: item.diagnosisCode,
            active: "\(item.active)",
            visitMinutes: String(item.visitMinutes),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryResultWindowViews(_ items: [PrimaryResultWindow]) -> [PrimaryResultWindowView] {
        var views: [PrimaryResultWindowView] = []
        for item in items {
            views.append(toPrimaryResultWindowView(item))
        }
        return views
    }

    static func sumPrimaryResultWindowView(_ view: PrimaryResultWindowView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedStartsAt)
    }
}
