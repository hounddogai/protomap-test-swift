import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool preference.
    final class FloatPoolPreferenceView {
        var code: String
        var name: String
        var updatedAt: String
        var createdAt: String
        var ward: String
        var version: String
        var durationMinutesText: String
        var specialty: String
        var statusLabel: String

        init(code: String, name: String, updatedAt: String, createdAt: String, ward: String, version: String, durationMinutesText: String, specialty: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.ward = ward
            self.version = version
            self.durationMinutesText = durationMinutesText
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolPreferenceView(_ item: FloatPoolPreference) -> FloatPoolPreferenceView {
        return FloatPoolPreferenceView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            updatedAt: String(item.updatedAt),
            createdAt: String(item.createdAt),
            ward: item.ward,
            version: String(item.version),
            durationMinutesText: String(item.durationMinutes),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolPreferenceViews(_ items: [FloatPoolPreference]) -> [FloatPoolPreferenceView] {
        var views: [FloatPoolPreferenceView] = []
        for item in items {
            views.append(toFloatPoolPreferenceView(item))
        }
        return views
    }

    static func sumFloatPoolPreferenceView(_ view: FloatPoolPreferenceView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedCreatedAt) + Double(parsedVersion)
    }
}
