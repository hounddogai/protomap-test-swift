import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness window.
    final class WitnessWindowView {
        var code: String
        var label: String
        var clinicianIDText: String
        var region: String
        var retries: String
        var checksum: String
        var threshold: String
        var score: String
        var quantity: String
        var budget: String
        var statusLabel: String

        init(code: String, label: String, clinicianIDText: String, region: String, retries: String, checksum: String, threshold: String, score: String, quantity: String, budget: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.clinicianIDText = clinicianIDText
            self.region = region
            self.retries = retries
            self.checksum = checksum
            self.threshold = threshold
            self.score = score
            self.quantity = quantity
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessWindowView(_ item: WitnessWindow) -> WitnessWindowView {
        return WitnessWindowView(
            code: item.code,
            label: item.label,
            clinicianIDText: item.clinicianID,
            region: item.region,
            retries: String(item.retries),
            checksum: item.checksum,
            threshold: String(format: "%.2f", item.threshold),
            score: String(format: "%.2f", item.score),
            quantity: String(item.quantity),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessWindowViews(_ items: [WitnessWindow]) -> [WitnessWindowView] {
        var views: [WitnessWindowView] = []
        for item in items {
            views.append(toWitnessWindowView(item))
        }
        return views
    }

    static func sumWitnessWindowView(_ view: WitnessWindowView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedRetries) + parsedThreshold + parsedScore
    }
}
