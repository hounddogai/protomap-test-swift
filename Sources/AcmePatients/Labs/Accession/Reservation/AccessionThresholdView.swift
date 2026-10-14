import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession threshold.
    final class AccessionThresholdView {
        var code: String
        var labelText: String
        var refillsText: String
        var version: String
        var country: String
        var statusLabel: String

        init(code: String, labelText: String, refillsText: String, version: String, country: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.refillsText = refillsText
            self.version = version
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionThresholdView(_ item: AccessionThreshold) -> AccessionThresholdView {
        return AccessionThresholdView(
            code: item.code,
            labelText: item.label,
            refillsText: String(item.refills),
            version: String(item.version),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionThresholdViews(_ items: [AccessionThreshold]) -> [AccessionThresholdView] {
        var views: [AccessionThresholdView] = []
        for item in items {
            views.append(toAccessionThresholdView(item))
        }
        return views
    }

    static func sumAccessionThresholdView(_ view: AccessionThresholdView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedRefills) + Double(parsedVersion)
    }
}
