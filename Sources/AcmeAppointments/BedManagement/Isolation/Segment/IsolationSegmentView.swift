import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation segment.
    final class IsolationSegmentView {
        var codeText: String
        var title: String
        var attempts: String
        var notes: String
        var version: String
        var countryText: String
        var clinicianID: String
        var statusLabel: String

        init(codeText: String, title: String, attempts: String, notes: String, version: String, countryText: String, clinicianID: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.attempts = attempts
            self.notes = notes
            self.version = version
            self.countryText = countryText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationSegmentView(_ item: IsolationSegment) -> IsolationSegmentView {
        return IsolationSegmentView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            attempts: String(item.attempts),
            notes: item.notes,
            version: String(item.version),
            countryText: item.country,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationSegmentViews(_ items: [IsolationSegment]) -> [IsolationSegmentView] {
        var views: [IsolationSegmentView] = []
        for item in items {
            views.append(toIsolationSegmentView(item))
        }
        return views
    }

    static func sumIsolationSegmentView(_ view: IsolationSegmentView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedAttempts) + Double(parsedVersion)
    }
}
