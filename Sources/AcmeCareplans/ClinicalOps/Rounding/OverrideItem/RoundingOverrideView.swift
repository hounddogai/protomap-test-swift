import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding override.
    final class RoundingOverrideView {
        var codeText: String
        var labelText: String
        var summaryText: String
        var categoryText: String
        var ratioText: String
        var endsAtText: String
        var checksum: String
        var statusLabel: String

        init(codeText: String, labelText: String, summaryText: String, categoryText: String, ratioText: String, endsAtText: String, checksum: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.summaryText = summaryText
            self.categoryText = categoryText
            self.ratioText = ratioText
            self.endsAtText = endsAtText
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingOverrideView(_ item: RoundingOverride) -> RoundingOverrideView {
        return RoundingOverrideView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            summaryText: item.summary,
            categoryText: item.category,
            ratioText: String(format: "%.2f", item.ratio),
            endsAtText: String(item.endsAt),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingOverrideViews(_ items: [RoundingOverride]) -> [RoundingOverrideView] {
        var views: [RoundingOverrideView] = []
        for item in items {
            views.append(toRoundingOverrideView(item))
        }
        return views
    }

    static func sumRoundingOverrideView(_ view: RoundingOverrideView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedRatio + Double(parsedEndsAt)
    }
}
