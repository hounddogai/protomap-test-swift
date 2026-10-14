import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default goal manifest.
    final class DefaultGoalManifestView {
        var code: String
        var label: String
        var discount: String
        var rate: String
        var endsAtText: String
        var country: String
        var specialty: String
        var visitMinutes: String
        var name: String
        var checksumText: String
        var statusLabel: String

        init(code: String, label: String, discount: String, rate: String, endsAtText: String, country: String, specialty: String, visitMinutes: String, name: String, checksumText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.rate = rate
            self.endsAtText = endsAtText
            self.country = country
            self.specialty = specialty
            self.visitMinutes = visitMinutes
            self.name = name
            self.checksumText = checksumText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultGoalManifestView(_ item: DefaultGoalManifest) -> DefaultGoalManifestView {
        return DefaultGoalManifestView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            rate: String(format: "%.2f", item.rate),
            endsAtText: String(item.endsAt),
            country: Kit.Text.truncate(item.country, limit: 120),
            specialty: item.specialty,
            visitMinutes: String(item.visitMinutes),
            name: item.name,
            checksumText: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultGoalManifestViews(_ items: [DefaultGoalManifest]) -> [DefaultGoalManifestView] {
        var views: [DefaultGoalManifestView] = []
        for item in items {
            views.append(toDefaultGoalManifestView(item))
        }
        return views
    }

    static func sumDefaultGoalManifestView(_ view: DefaultGoalManifestView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedDiscount + parsedRate + Double(parsedEndsAt)
    }
}
