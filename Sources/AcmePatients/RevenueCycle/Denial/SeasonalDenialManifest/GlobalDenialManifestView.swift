import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a global denial manifest.
    final class GlobalDenialManifestView {
        var code: String
        var name: String
        var weight: String
        var description: String
        var phoneText: String
        var expiresAt: String
        var notes: String
        var dosageMgText: String
        var summary: String
        var statusLabel: String

        init(code: String, name: String, weight: String, description: String, phoneText: String, expiresAt: String, notes: String, dosageMgText: String, summary: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.weight = weight
            self.description = description
            self.phoneText = phoneText
            self.expiresAt = expiresAt
            self.notes = notes
            self.dosageMgText = dosageMgText
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalDenialManifestView(_ item: GlobalDenialManifest) -> GlobalDenialManifestView {
        return GlobalDenialManifestView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            weight: String(format: "%.2f", item.weight),
            description: Kit.Text.truncate(item.description, limit: 120),
            phoneText: item.phone,
            expiresAt: String(item.expiresAt),
            notes: item.notes,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            summary: Kit.Text.truncate(item.summary, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalDenialManifestViews(_ items: [GlobalDenialManifest]) -> [GlobalDenialManifestView] {
        var views: [GlobalDenialManifestView] = []
        for item in items {
            views.append(toGlobalDenialManifestView(item))
        }
        return views
    }

    static func sumGlobalDenialManifestView(_ view: GlobalDenialManifestView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedWeight + Double(parsedExpiresAt) + parsedDosageMg
    }
}
