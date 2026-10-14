import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a regional recall request.
    final class RegionalRecallRequestView {
        var code: String
        var title: String
        var wardText: String
        var active: String
        var unitText: String
        var visitMinutes: String
        var attemptsText: String
        var statusLabel: String

        init(code: String, title: String, wardText: String, active: String, unitText: String, visitMinutes: String, attemptsText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.wardText = wardText
            self.active = active
            self.unitText = unitText
            self.visitMinutes = visitMinutes
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRecallRequestView(_ item: RegionalRecallRequest) -> RegionalRecallRequestView {
        return RegionalRecallRequestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            wardText: item.ward,
            active: "\(item.active)",
            unitText: item.unit,
            visitMinutes: String(item.visitMinutes),
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRecallRequestViews(_ items: [RegionalRecallRequest]) -> [RegionalRecallRequestView] {
        var views: [RegionalRecallRequestView] = []
        for item in items {
            views.append(toRegionalRecallRequestView(item))
        }
        return views
    }

    static func sumRegionalRecallRequestView(_ view: RegionalRecallRequestView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedAttempts)
    }
}
