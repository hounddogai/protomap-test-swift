import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted program rollup.
    final class WeightedProgramRollupView {
        var code: String
        var label: String
        var bed: String
        var region: String
        var pinnedText: String
        var updatedAt: String
        var title: String
        var diagnosisCode: String
        var payer: String
        var segment: String
        var statusLabel: String

        init(code: String, label: String, bed: String, region: String, pinnedText: String, updatedAt: String, title: String, diagnosisCode: String, payer: String, segment: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.bed = bed
            self.region = region
            self.pinnedText = pinnedText
            self.updatedAt = updatedAt
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.payer = payer
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedProgramRollupView(_ item: WeightedProgramRollup) -> WeightedProgramRollupView {
        return WeightedProgramRollupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            bed: item.bed,
            region: item.region,
            pinnedText: "\(item.pinned)",
            updatedAt: String(item.updatedAt),
            title: item.title,
            diagnosisCode: item.diagnosisCode,
            payer: item.payer,
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedProgramRollupViews(_ items: [WeightedProgramRollup]) -> [WeightedProgramRollupView] {
        var views: [WeightedProgramRollupView] = []
        for item in items {
            views.append(toWeightedProgramRollupView(item))
        }
        return views
    }

    static func sumWeightedProgramRollupView(_ view: WeightedProgramRollupView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
