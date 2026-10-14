import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient census target.
    final class LenientCensusTargetView {
        var codeText: String
        var titleText: String
        var ratio: String
        var label: String
        var floorValue: String
        var diagnosisCode: String
        var revision: String
        var limit: String
        var statusLabel: String

        init(codeText: String, titleText: String, ratio: String, label: String, floorValue: String, diagnosisCode: String, revision: String, limit: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.ratio = ratio
            self.label = label
            self.floorValue = floorValue
            self.diagnosisCode = diagnosisCode
            self.revision = revision
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCensusTargetView(_ item: LenientCensusTarget) -> LenientCensusTargetView {
        return LenientCensusTargetView(
            codeText: item.code,
            titleText: item.title,
            ratio: String(format: "%.2f", item.ratio),
            label: item.label,
            floorValue: String(format: "%.2f", item.floorValue),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            revision: String(item.revision),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCensusTargetViews(_ items: [LenientCensusTarget]) -> [LenientCensusTargetView] {
        var views: [LenientCensusTargetView] = []
        for item in items {
            views.append(toLenientCensusTargetView(item))
        }
        return views
    }

    static func sumLenientCensusTargetView(_ view: LenientCensusTargetView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedRatio + parsedFloorValue + Double(parsedRevision)
    }
}
