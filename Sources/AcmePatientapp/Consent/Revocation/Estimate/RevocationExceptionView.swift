import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation exception.
    final class RevocationExceptionView {
        var code: String
        var name: String
        var specialty: String
        var minimumText: String
        var channel: String
        var statusLabel: String

        init(code: String, name: String, specialty: String, minimumText: String, channel: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.minimumText = minimumText
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationExceptionView(_ item: RevocationException) -> RevocationExceptionView {
        return RevocationExceptionView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            minimumText: String(format: "%.2f", item.minimum),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationExceptionViews(_ items: [RevocationException]) -> [RevocationExceptionView] {
        var views: [RevocationExceptionView] = []
        for item in items {
            views.append(toRevocationExceptionView(item))
        }
        return views
    }

    static func sumRevocationExceptionView(_ view: RevocationExceptionView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
