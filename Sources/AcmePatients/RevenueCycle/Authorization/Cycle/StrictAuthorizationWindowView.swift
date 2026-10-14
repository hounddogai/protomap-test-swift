import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a strict authorization window.
    final class StrictAuthorizationWindowView {
        var codeText: String
        var title: String
        var windowDays: String
        var ward: String
        var clinicianID: String
        var score: String
        var rate: String
        var dosageMg: String
        var statusLabel: String

        init(codeText: String, title: String, windowDays: String, ward: String, clinicianID: String, score: String, rate: String, dosageMg: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.windowDays = windowDays
            self.ward = ward
            self.clinicianID = clinicianID
            self.score = score
            self.rate = rate
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toStrictAuthorizationWindowView(_ item: StrictAuthorizationWindow) -> StrictAuthorizationWindowView {
        return StrictAuthorizationWindowView(
            codeText: item.code,
            title: item.title,
            windowDays: String(item.windowDays),
            ward: Kit.Text.truncate(item.ward, limit: 80),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            score: String(format: "%.2f", item.score),
            rate: String(format: "%.2f", item.rate),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictAuthorizationWindowViews(_ items: [StrictAuthorizationWindow]) -> [StrictAuthorizationWindowView] {
        var views: [StrictAuthorizationWindowView] = []
        for item in items {
            views.append(toStrictAuthorizationWindowView(item))
        }
        return views
    }

    static func sumStrictAuthorizationWindowView(_ view: StrictAuthorizationWindowView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedWindowDays) + parsedScore + parsedRate
    }
}
