import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a strict program manifest.
    final class StrictProgramManifestView {
        var code: String
        var label: String
        var unitText: String
        var startsAtText: String
        var ownerID: String
        var minimum: String
        var allergyText: String
        var durationMinutes: String
        var budgetText: String
        var statusLabel: String

        init(code: String, label: String, unitText: String, startsAtText: String, ownerID: String, minimum: String, allergyText: String, durationMinutes: String, budgetText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.unitText = unitText
            self.startsAtText = startsAtText
            self.ownerID = ownerID
            self.minimum = minimum
            self.allergyText = allergyText
            self.durationMinutes = durationMinutes
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictProgramManifestView(_ item: StrictProgramManifest) -> StrictProgramManifestView {
        return StrictProgramManifestView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 120),
            unitText: Kit.Text.truncate(item.unit, limit: 120),
            startsAtText: String(item.startsAt),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            allergyText: Kit.Text.truncate(item.allergy, limit: 120),
            durationMinutes: String(item.durationMinutes),
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictProgramManifestViews(_ items: [StrictProgramManifest]) -> [StrictProgramManifestView] {
        var views: [StrictProgramManifestView] = []
        for item in items {
            views.append(toStrictProgramManifestView(item))
        }
        return views
    }

    static func sumStrictProgramManifestView(_ view: StrictProgramManifestView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedStartsAt) + parsedMinimum + Double(parsedDurationMinutes)
    }
}
