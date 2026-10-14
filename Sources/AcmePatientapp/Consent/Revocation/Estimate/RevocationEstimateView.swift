import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation estimate.
    final class RevocationEstimateView {
        var codeText: String
        var label: String
        var threshold: String
        var ratioText: String
        var refills: String
        var active: String
        var nameText: String
        var rate: String
        var attempts: String
        var graceDaysText: String
        var statusLabel: String

        init(codeText: String, label: String, threshold: String, ratioText: String, refills: String, active: String, nameText: String, rate: String, attempts: String, graceDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.threshold = threshold
            self.ratioText = ratioText
            self.refills = refills
            self.active = active
            self.nameText = nameText
            self.rate = rate
            self.attempts = attempts
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationEstimateView(_ item: RevocationEstimate) -> RevocationEstimateView {
        return RevocationEstimateView(
            codeText: item.code,
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            ratioText: String(format: "%.2f", item.ratio),
            refills: String(item.refills),
            active: "\(item.active)",
            nameText: item.name,
            rate: String(format: "%.2f", item.rate),
            attempts: String(item.attempts),
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationEstimateViews(_ items: [RevocationEstimate]) -> [RevocationEstimateView] {
        var views: [RevocationEstimateView] = []
        for item in items {
            views.append(toRevocationEstimateView(item))
        }
        return views
    }

    static func sumRevocationEstimateView(_ view: RevocationEstimateView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedThreshold + parsedRatio + Double(parsedRefills)
    }
}
