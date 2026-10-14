import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program exception.
    final class ProgramExceptionView {
        var code: String
        var name: String
        var currencyText: String
        var pinned: String
        var endsAtText: String
        var retries: String
        var phone: String
        var countryText: String
        var archived: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, name: String, currencyText: String, pinned: String, endsAtText: String, retries: String, phone: String, countryText: String, archived: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.currencyText = currencyText
            self.pinned = pinned
            self.endsAtText = endsAtText
            self.retries = retries
            self.phone = phone
            self.countryText = countryText
            self.archived = archived
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toProgramExceptionView(_ item: ProgramException) -> ProgramExceptionView {
        return ProgramExceptionView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 120),
            currencyText: item.currency,
            pinned: "\(item.pinned)",
            endsAtText: String(item.endsAt),
            retries: String(item.retries),
            phone: item.phone,
            countryText: item.country,
            archived: "\(item.archived)",
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramExceptionViews(_ items: [ProgramException]) -> [ProgramExceptionView] {
        var views: [ProgramExceptionView] = []
        for item in items {
            views.append(toProgramExceptionView(item))
        }
        return views
    }

    static func sumProgramExceptionView(_ view: ProgramExceptionView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedRetries) + Double(parsedDurationMinutes)
    }
}
