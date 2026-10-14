import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary float pool manifest.
    final class PrimaryFloatPoolManifestView {
        var code: String
        var label: String
        var cost: String
        var windowDays: String
        var score: String
        var segment: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(code: String, label: String, cost: String, windowDays: String, score: String, segment: String, diagnosisCodeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.cost = cost
            self.windowDays = windowDays
            self.score = score
            self.segment = segment
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryFloatPoolManifestView(_ item: PrimaryFloatPoolManifest) -> PrimaryFloatPoolManifestView {
        return PrimaryFloatPoolManifestView(
            code: item.code,
            label: item.label,
            cost: String(format: "%.2f", item.cost),
            windowDays: String(item.windowDays),
            score: String(format: "%.2f", item.score),
            segment: Kit.Text.truncate(item.segment, limit: 40),
            diagnosisCodeText: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryFloatPoolManifestViews(_ items: [PrimaryFloatPoolManifest]) -> [PrimaryFloatPoolManifestView] {
        var views: [PrimaryFloatPoolManifestView] = []
        for item in items {
            views.append(toPrimaryFloatPoolManifestView(item))
        }
        return views
    }

    static func sumPrimaryFloatPoolManifestView(_ view: PrimaryFloatPoolManifestView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedCost + Double(parsedWindowDays) + parsedScore
    }
}
