import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default program override.
    final class DefaultProgramOverrideView {
        var code: String
        var label: String
        var timezoneText: String
        var procedureCode: String
        var endsAtText: String
        var externalRef: String
        var phoneText: String
        var statusLabel: String

        init(code: String, label: String, timezoneText: String, procedureCode: String, endsAtText: String, externalRef: String, phoneText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.timezoneText = timezoneText
            self.procedureCode = procedureCode
            self.endsAtText = endsAtText
            self.externalRef = externalRef
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultProgramOverrideView(_ item: DefaultProgramOverride) -> DefaultProgramOverrideView {
        return DefaultProgramOverrideView(
            code: item.code,
            label: item.label,
            timezoneText: item.timezone,
            procedureCode: item.procedureCode,
            endsAtText: String(item.endsAt),
            externalRef: item.externalRef,
            phoneText: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultProgramOverrideViews(_ items: [DefaultProgramOverride]) -> [DefaultProgramOverrideView] {
        var views: [DefaultProgramOverrideView] = []
        for item in items {
            views.append(toDefaultProgramOverrideView(item))
        }
        return views
    }

    static func sumDefaultProgramOverrideView(_ view: DefaultProgramOverrideView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
