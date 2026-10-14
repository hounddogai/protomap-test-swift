import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling specimen entry.
    final class RollingSpecimenEntryView {
        var code: String
        var titleText: String
        var version: String
        var minimumText: String
        var limit: String
        var phoneText: String
        var specialtyText: String
        var facilityText: String
        var revision: String
        var windowDays: String
        var statusLabel: String

        init(code: String, titleText: String, version: String, minimumText: String, limit: String, phoneText: String, specialtyText: String, facilityText: String, revision: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.version = version
            self.minimumText = minimumText
            self.limit = limit
            self.phoneText = phoneText
            self.specialtyText = specialtyText
            self.facilityText = facilityText
            self.revision = revision
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toRollingSpecimenEntryView(_ item: RollingSpecimenEntry) -> RollingSpecimenEntryView {
        return RollingSpecimenEntryView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            version: String(item.version),
            minimumText: String(format: "%.2f", item.minimum),
            limit: String(item.limit),
            phoneText: item.phone,
            specialtyText: item.specialty,
            facilityText: Kit.Text.truncate(item.facility, limit: 40),
            revision: String(item.revision),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingSpecimenEntryViews(_ items: [RollingSpecimenEntry]) -> [RollingSpecimenEntryView] {
        var views: [RollingSpecimenEntryView] = []
        for item in items {
            views.append(toRollingSpecimenEntryView(item))
        }
        return views
    }

    static func sumRollingSpecimenEntryView(_ view: RollingSpecimenEntryView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedVersion) + parsedMinimum + Double(parsedLimit)
    }
}
