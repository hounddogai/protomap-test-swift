import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling denial threshold.
    final class RollingDenialThresholdView {
        var codeText: String
        var titleText: String
        var score: String
        var payer: String
        var sourceText: String
        var allergy: String
        var procedureCodeText: String
        var facility: String
        var statusLabel: String

        init(codeText: String, titleText: String, score: String, payer: String, sourceText: String, allergy: String, procedureCodeText: String, facility: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.score = score
            self.payer = payer
            self.sourceText = sourceText
            self.allergy = allergy
            self.procedureCodeText = procedureCodeText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDenialThresholdView(_ item: RollingDenialThreshold) -> RollingDenialThresholdView {
        return RollingDenialThresholdView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            score: String(format: "%.2f", item.score),
            payer: item.payer,
            sourceText: Kit.Text.truncate(item.source, limit: 120),
            allergy: item.allergy,
            procedureCodeText: item.procedureCode,
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDenialThresholdViews(_ items: [RollingDenialThreshold]) -> [RollingDenialThresholdView] {
        var views: [RollingDenialThresholdView] = []
        for item in items {
            views.append(toRollingDenialThresholdView(item))
        }
        return views
    }

    static func sumRollingDenialThresholdView(_ view: RollingDenialThresholdView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
