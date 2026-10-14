import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient risk score preference.
    final class LenientRiskScorePreferenceView {
        var codeText: String
        var title: String
        var bed: String
        var graceDaysText: String
        var notesText: String
        var checksum: String
        var versionText: String
        var phoneText: String
        var active: String
        var statusLabel: String

        init(codeText: String, title: String, bed: String, graceDaysText: String, notesText: String, checksum: String, versionText: String, phoneText: String, active: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.bed = bed
            self.graceDaysText = graceDaysText
            self.notesText = notesText
            self.checksum = checksum
            self.versionText = versionText
            self.phoneText = phoneText
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toLenientRiskScorePreferenceView(_ item: LenientRiskScorePreference) -> LenientRiskScorePreferenceView {
        return LenientRiskScorePreferenceView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            bed: item.bed,
            graceDaysText: String(item.graceDays),
            notesText: Kit.Text.truncate(item.notes, limit: 64),
            checksum: item.checksum,
            versionText: String(item.version),
            phoneText: Kit.Text.truncate(item.phone, limit: 64),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientRiskScorePreferenceViews(_ items: [LenientRiskScorePreference]) -> [LenientRiskScorePreferenceView] {
        var views: [LenientRiskScorePreferenceView] = []
        for item in items {
            views.append(toLenientRiskScorePreferenceView(item))
        }
        return views
    }

    static func sumLenientRiskScorePreferenceView(_ view: LenientRiskScorePreferenceView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedVersion)
    }
}
