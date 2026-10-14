import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a default formulary override.
    final class DefaultFormularyOverrideView {
        var codeText: String
        var name: String
        var updatedAt: String
        var limit: String
        var windowDays: String
        var archivedText: String
        var ward: String
        var dosageMgText: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, name: String, updatedAt: String, limit: String, windowDays: String, archivedText: String, ward: String, dosageMgText: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.updatedAt = updatedAt
            self.limit = limit
            self.windowDays = windowDays
            self.archivedText = archivedText
            self.ward = ward
            self.dosageMgText = dosageMgText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultFormularyOverrideView(_ item: DefaultFormularyOverride) -> DefaultFormularyOverrideView {
        return DefaultFormularyOverrideView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            updatedAt: String(item.updatedAt),
            limit: String(item.limit),
            windowDays: String(item.windowDays),
            archivedText: "\(item.archived)",
            ward: Kit.Text.truncate(item.ward, limit: 64),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultFormularyOverrideViews(_ items: [DefaultFormularyOverride]) -> [DefaultFormularyOverrideView] {
        var views: [DefaultFormularyOverrideView] = []
        for item in items {
            views.append(toDefaultFormularyOverrideView(item))
        }
        return views
    }

    static func sumDefaultFormularyOverrideView(_ view: DefaultFormularyOverrideView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedLimit) + Double(parsedWindowDays)
    }
}
