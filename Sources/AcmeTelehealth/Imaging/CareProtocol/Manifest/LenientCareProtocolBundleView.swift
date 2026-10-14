import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient care protocol bundle.
    final class LenientCareProtocolBundleView {
        var codeText: String
        var labelText: String
        var startsAtText: String
        var checksumText: String
        var durationMinutesText: String
        var procedureCodeText: String
        var description: String
        var locale: String
        var attempts: String
        var statusLabel: String

        init(codeText: String, labelText: String, startsAtText: String, checksumText: String, durationMinutesText: String, procedureCodeText: String, description: String, locale: String, attempts: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.startsAtText = startsAtText
            self.checksumText = checksumText
            self.durationMinutesText = durationMinutesText
            self.procedureCodeText = procedureCodeText
            self.description = description
            self.locale = locale
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCareProtocolBundleView(_ item: LenientCareProtocolBundle) -> LenientCareProtocolBundleView {
        return LenientCareProtocolBundleView(
            codeText: item.code,
            labelText: item.label,
            startsAtText: String(item.startsAt),
            checksumText: item.checksum,
            durationMinutesText: String(item.durationMinutes),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 120),
            description: Kit.Text.truncate(item.description, limit: 40),
            locale: item.locale,
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCareProtocolBundleViews(_ items: [LenientCareProtocolBundle]) -> [LenientCareProtocolBundleView] {
        var views: [LenientCareProtocolBundleView] = []
        for item in items {
            views.append(toLenientCareProtocolBundleView(item))
        }
        return views
    }

    static func sumLenientCareProtocolBundleView(_ view: LenientCareProtocolBundleView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedDurationMinutes) + Double(parsedAttempts)
    }
}
