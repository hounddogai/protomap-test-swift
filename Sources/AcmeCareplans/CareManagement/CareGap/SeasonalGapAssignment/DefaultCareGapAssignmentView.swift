import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default care gap assignment.
    final class DefaultCareGapAssignmentView {
        var code: String
        var name: String
        var capacity: String
        var country: String
        var windowDays: String
        var limit: String
        var ratio: String
        var copay: String
        var contactEmailText: String
        var archivedText: String
        var statusLabel: String

        init(code: String, name: String, capacity: String, country: String, windowDays: String, limit: String, ratio: String, copay: String, contactEmailText: String, archivedText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.country = country
            self.windowDays = windowDays
            self.limit = limit
            self.ratio = ratio
            self.copay = copay
            self.contactEmailText = contactEmailText
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCareGapAssignmentView(_ item: DefaultCareGapAssignment) -> DefaultCareGapAssignmentView {
        return DefaultCareGapAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            capacity: String(item.capacity),
            country: Kit.Text.truncate(item.country, limit: 120),
            windowDays: String(item.windowDays),
            limit: String(item.limit),
            ratio: String(format: "%.2f", item.ratio),
            copay: String(format: "%.2f", item.copay),
            contactEmailText: item.contactEmail,
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCareGapAssignmentViews(_ items: [DefaultCareGapAssignment]) -> [DefaultCareGapAssignmentView] {
        var views: [DefaultCareGapAssignmentView] = []
        for item in items {
            views.append(toDefaultCareGapAssignmentView(item))
        }
        return views
    }

    static func sumDefaultCareGapAssignmentView(_ view: DefaultCareGapAssignmentView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedCapacity) + Double(parsedWindowDays) + Double(parsedLimit)
    }
}
