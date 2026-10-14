import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy program variance.
    final class LegacyProgramVarianceView {
        var code: String
        var title: String
        var locale: String
        var revisionText: String
        var weightText: String
        var statusLabel: String

        init(code: String, title: String, locale: String, revisionText: String, weightText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.locale = locale
            self.revisionText = revisionText
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyProgramVarianceView(_ item: LegacyProgramVariance) -> LegacyProgramVarianceView {
        return LegacyProgramVarianceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            locale: item.locale,
            revisionText: String(item.revision),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyProgramVarianceViews(_ items: [LegacyProgramVariance]) -> [LegacyProgramVarianceView] {
        var views: [LegacyProgramVarianceView] = []
        for item in items {
            views.append(toLegacyProgramVarianceView(item))
        }
        return views
    }

    static func sumLegacyProgramVarianceView(_ view: LegacyProgramVarianceView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedRevision) + parsedWeight
    }
}
