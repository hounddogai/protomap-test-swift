import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary recall request.
    final class PrimaryRecallRequestView {
        var code: String
        var labelText: String
        var endsAtText: String
        var contactEmailText: String
        var windowDays: String
        var title: String
        var statusLabel: String

        init(code: String, labelText: String, endsAtText: String, contactEmailText: String, windowDays: String, title: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.endsAtText = endsAtText
            self.contactEmailText = contactEmailText
            self.windowDays = windowDays
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRecallRequestView(_ item: PrimaryRecallRequest) -> PrimaryRecallRequestView {
        return PrimaryRecallRequestView(
            code: item.code,
            labelText: item.label,
            endsAtText: String(item.endsAt),
            contactEmailText: item.contactEmail,
            windowDays: String(item.windowDays),
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRecallRequestViews(_ items: [PrimaryRecallRequest]) -> [PrimaryRecallRequestView] {
        var views: [PrimaryRecallRequestView] = []
        for item in items {
            views.append(toPrimaryRecallRequestView(item))
        }
        return views
    }

    static func sumPrimaryRecallRequestView(_ view: PrimaryRecallRequestView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedWindowDays)
    }
}
