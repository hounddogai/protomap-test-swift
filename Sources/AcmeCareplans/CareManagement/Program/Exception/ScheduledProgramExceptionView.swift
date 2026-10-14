import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled program exception.
    final class ScheduledProgramExceptionView {
        var code: String
        var label: String
        var copay: String
        var createdAt: String
        var locale: String
        var ward: String
        var specialty: String
        var statusLabel: String

        init(code: String, label: String, copay: String, createdAt: String, locale: String, ward: String, specialty: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.copay = copay
            self.createdAt = createdAt
            self.locale = locale
            self.ward = ward
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledProgramExceptionView(_ item: ScheduledProgramException) -> ScheduledProgramExceptionView {
        return ScheduledProgramExceptionView(
            code: item.code,
            label: item.label,
            copay: String(format: "%.2f", item.copay),
            createdAt: String(item.createdAt),
            locale: Kit.Text.truncate(item.locale, limit: 80),
            ward: item.ward,
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledProgramExceptionViews(_ items: [ScheduledProgramException]) -> [ScheduledProgramExceptionView] {
        var views: [ScheduledProgramExceptionView] = []
        for item in items {
            views.append(toScheduledProgramExceptionView(item))
        }
        return views
    }

    static func sumScheduledProgramExceptionView(_ view: ScheduledProgramExceptionView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedCopay + Double(parsedCreatedAt)
    }
}
