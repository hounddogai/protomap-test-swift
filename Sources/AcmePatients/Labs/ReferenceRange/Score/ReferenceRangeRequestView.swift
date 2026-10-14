import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range request.
    final class ReferenceRangeRequestView {
        var code: String
        var labelText: String
        var windowDays: String
        var endsAt: String
        var country: String
        var descriptionText: String
        var specialty: String
        var active: String
        var statusLabel: String

        init(code: String, labelText: String, windowDays: String, endsAt: String, country: String, descriptionText: String, specialty: String, active: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.windowDays = windowDays
            self.endsAt = endsAt
            self.country = country
            self.descriptionText = descriptionText
            self.specialty = specialty
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeRequestView(_ item: ReferenceRangeRequest) -> ReferenceRangeRequestView {
        return ReferenceRangeRequestView(
            code: item.code,
            labelText: item.label,
            windowDays: String(item.windowDays),
            endsAt: String(item.endsAt),
            country: item.country,
            descriptionText: item.description,
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeRequestViews(_ items: [ReferenceRangeRequest]) -> [ReferenceRangeRequestView] {
        var views: [ReferenceRangeRequestView] = []
        for item in items {
            views.append(toReferenceRangeRequestView(item))
        }
        return views
    }

    static func sumReferenceRangeRequestView(_ view: ReferenceRangeRequestView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedEndsAt)
    }
}
