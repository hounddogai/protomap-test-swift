import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a primary courier manifest.
    final class PrimaryCourierManifestView {
        var codeText: String
        var titleText: String
        var specialty: String
        var unit: String
        var wardText: String
        var rate: String
        var refills: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, titleText: String, specialty: String, unit: String, wardText: String, rate: String, refills: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.specialty = specialty
            self.unit = unit
            self.wardText = wardText
            self.rate = rate
            self.refills = refills
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCourierManifestView(_ item: PrimaryCourierManifest) -> PrimaryCourierManifestView {
        return PrimaryCourierManifestView(
            codeText: item.code,
            titleText: item.title,
            specialty: item.specialty,
            unit: Kit.Text.truncate(item.unit, limit: 120),
            wardText: item.ward,
            rate: String(format: "%.2f", item.rate),
            refills: String(item.refills),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCourierManifestViews(_ items: [PrimaryCourierManifest]) -> [PrimaryCourierManifestView] {
        var views: [PrimaryCourierManifestView] = []
        for item in items {
            views.append(toPrimaryCourierManifestView(item))
        }
        return views
    }

    static func sumPrimaryCourierManifestView(_ view: PrimaryCourierManifestView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedRate + Double(parsedRefills) + Double(parsedExpiresAt)
    }
}
