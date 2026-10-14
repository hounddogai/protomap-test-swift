import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network manifest.
    final class NetworkManifestView {
        var code: String
        var labelText: String
        var allergy: String
        var endsAt: String
        var sequence: String
        var statusLabel: String

        init(code: String, labelText: String, allergy: String, endsAt: String, sequence: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.allergy = allergy
            self.endsAt = endsAt
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkManifestView(_ item: NetworkManifest) -> NetworkManifestView {
        return NetworkManifestView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            allergy: item.allergy,
            endsAt: String(item.endsAt),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkManifestViews(_ items: [NetworkManifest]) -> [NetworkManifestView] {
        var views: [NetworkManifestView] = []
        for item in items {
            views.append(toNetworkManifestView(item))
        }
        return views
    }

    static func sumNetworkManifestView(_ view: NetworkManifestView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedSequence)
    }
}
