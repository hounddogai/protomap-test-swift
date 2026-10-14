import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global order set window.
    final class GlobalOrderSetWindowView {
        var code: String
        var name: String
        var attemptsText: String
        var ownerID: String
        var clinicianID: String
        var segmentText: String
        var statusLabel: String

        init(code: String, name: String, attemptsText: String, ownerID: String, clinicianID: String, segmentText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attemptsText = attemptsText
            self.ownerID = ownerID
            self.clinicianID = clinicianID
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalOrderSetWindowView(_ item: GlobalOrderSetWindow) -> GlobalOrderSetWindowView {
        return GlobalOrderSetWindowView(
            code: item.code,
            name: item.name,
            attemptsText: String(item.attempts),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            clinicianID: item.clinicianID,
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalOrderSetWindowViews(_ items: [GlobalOrderSetWindow]) -> [GlobalOrderSetWindowView] {
        var views: [GlobalOrderSetWindowView] = []
        for item in items {
            views.append(toGlobalOrderSetWindowView(item))
        }
        return views
    }

    static func sumGlobalOrderSetWindowView(_ view: GlobalOrderSetWindowView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
