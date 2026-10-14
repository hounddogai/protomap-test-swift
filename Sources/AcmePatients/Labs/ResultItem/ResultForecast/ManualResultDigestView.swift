import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a manual result digest.
    final class ManualResultDigestView {
        var code: String
        var titleText: String
        var externalRef: String
        var segment: String
        var phoneText: String
        var clinicianID: String
        var score: String
        var statusLabel: String

        init(code: String, titleText: String, externalRef: String, segment: String, phoneText: String, clinicianID: String, score: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.externalRef = externalRef
            self.segment = segment
            self.phoneText = phoneText
            self.clinicianID = clinicianID
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toManualResultDigestView(_ item: ManualResultDigest) -> ManualResultDigestView {
        return ManualResultDigestView(
            code: item.code,
            titleText: item.title,
            externalRef: item.externalRef,
            segment: item.segment,
            phoneText: Kit.Text.truncate(item.phone, limit: 40),
            clinicianID: item.clinicianID,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualResultDigestViews(_ items: [ManualResultDigest]) -> [ManualResultDigestView] {
        var views: [ManualResultDigestView] = []
        for item in items {
            views.append(toManualResultDigestView(item))
        }
        return views
    }

    static func sumManualResultDigestView(_ view: ManualResultDigestView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
