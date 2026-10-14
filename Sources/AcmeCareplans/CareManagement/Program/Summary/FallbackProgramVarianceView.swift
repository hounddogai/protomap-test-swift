import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback program variance.
    final class FallbackProgramVarianceView {
        var code: String
        var titleText: String
        var threshold: String
        var margin: String
        var copayText: String
        var statusLabel: String

        init(code: String, titleText: String, threshold: String, margin: String, copayText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.threshold = threshold
            self.margin = margin
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackProgramVarianceView(_ item: FallbackProgramVariance) -> FallbackProgramVarianceView {
        return FallbackProgramVarianceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            threshold: String(format: "%.2f", item.threshold),
            margin: String(format: "%.2f", item.margin),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackProgramVarianceViews(_ items: [FallbackProgramVariance]) -> [FallbackProgramVarianceView] {
        var views: [FallbackProgramVarianceView] = []
        for item in items {
            views.append(toFallbackProgramVarianceView(item))
        }
        return views
    }

    static func sumFallbackProgramVarianceView(_ view: FallbackProgramVarianceView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedThreshold + parsedMargin + parsedCopay
    }
}
