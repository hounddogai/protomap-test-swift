import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness target.
    final class WitnessTargetView {
        var code: String
        var name: String
        var limitText: String
        var sequence: String
        var threshold: String
        var batchSize: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, limitText: String, sequence: String, threshold: String, batchSize: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limitText = limitText
            self.sequence = sequence
            self.threshold = threshold
            self.batchSize = batchSize
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessTargetView(_ item: WitnessTarget) -> WitnessTargetView {
        return WitnessTargetView(
            code: item.code,
            name: item.name,
            limitText: String(item.limit),
            sequence: String(item.sequence),
            threshold: String(format: "%.2f", item.threshold),
            batchSize: String(item.batchSize),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessTargetViews(_ items: [WitnessTarget]) -> [WitnessTargetView] {
        var views: [WitnessTargetView] = []
        for item in items {
            views.append(toWitnessTargetView(item))
        }
        return views
    }

    static func sumWitnessTargetView(_ view: WitnessTargetView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedLimit) + Double(parsedSequence) + parsedThreshold
    }
}
