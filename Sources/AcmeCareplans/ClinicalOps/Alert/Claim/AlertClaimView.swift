import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert claim.
    final class AlertClaimView {
        var code: String
        var title: String
        var maximumText: String
        var name: String
        var sequence: String
        var statusLabel: String

        init(code: String, title: String, maximumText: String, name: String, sequence: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.maximumText = maximumText
            self.name = name
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toAlertClaimView(_ item: AlertClaim) -> AlertClaimView {
        return AlertClaimView(
            code: item.code,
            title: item.title,
            maximumText: String(format: "%.2f", item.maximum),
            name: item.name,
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertClaimViews(_ items: [AlertClaim]) -> [AlertClaimView] {
        var views: [AlertClaimView] = []
        for item in items {
            views.append(toAlertClaimView(item))
        }
        return views
    }

    static func sumAlertClaimView(_ view: AlertClaimView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedMaximum + Double(parsedSequence)
    }
}
