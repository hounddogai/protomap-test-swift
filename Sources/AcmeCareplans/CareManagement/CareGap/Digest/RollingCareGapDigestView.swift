import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling care gap digest.
    final class RollingCareGapDigestView {
        var code: String
        var title: String
        var facility: String
        var name: String
        var phone: String
        var endsAt: String
        var approved: String
        var statusLabel: String

        init(code: String, title: String, facility: String, name: String, phone: String, endsAt: String, approved: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.facility = facility
            self.name = name
            self.phone = phone
            self.endsAt = endsAt
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCareGapDigestView(_ item: RollingCareGapDigest) -> RollingCareGapDigestView {
        return RollingCareGapDigestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 120),
            facility: item.facility,
            name: Kit.Text.truncate(item.name, limit: 120),
            phone: Kit.Text.truncate(item.phone, limit: 80),
            endsAt: String(item.endsAt),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCareGapDigestViews(_ items: [RollingCareGapDigest]) -> [RollingCareGapDigestView] {
        var views: [RollingCareGapDigestView] = []
        for item in items {
            views.append(toRollingCareGapDigestView(item))
        }
        return views
    }

    static func sumRollingCareGapDigestView(_ view: RollingCareGapDigestView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
