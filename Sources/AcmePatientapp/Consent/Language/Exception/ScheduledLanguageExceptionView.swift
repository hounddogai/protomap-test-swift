import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled language exception.
    final class ScheduledLanguageExceptionView {
        var code: String
        var labelText: String
        var unitText: String
        var startsAt: String
        var phoneText: String
        var checksumText: String
        var categoryText: String
        var refills: String
        var pinned: String
        var statusLabel: String

        init(code: String, labelText: String, unitText: String, startsAt: String, phoneText: String, checksumText: String, categoryText: String, refills: String, pinned: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.unitText = unitText
            self.startsAt = startsAt
            self.phoneText = phoneText
            self.checksumText = checksumText
            self.categoryText = categoryText
            self.refills = refills
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledLanguageExceptionView(_ item: ScheduledLanguageException) -> ScheduledLanguageExceptionView {
        return ScheduledLanguageExceptionView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            startsAt: String(item.startsAt),
            phoneText: item.phone,
            checksumText: item.checksum,
            categoryText: item.category,
            refills: String(item.refills),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledLanguageExceptionViews(_ items: [ScheduledLanguageException]) -> [ScheduledLanguageExceptionView] {
        var views: [ScheduledLanguageExceptionView] = []
        for item in items {
            views.append(toScheduledLanguageExceptionView(item))
        }
        return views
    }

    static func sumScheduledLanguageExceptionView(_ view: ScheduledLanguageExceptionView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedRefills)
    }
}
