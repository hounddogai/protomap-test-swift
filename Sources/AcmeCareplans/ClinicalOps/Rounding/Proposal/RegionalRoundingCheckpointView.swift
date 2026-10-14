import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional rounding checkpoint.
    final class RegionalRoundingCheckpointView {
        var codeText: String
        var label: String
        var externalRefText: String
        var regionText: String
        var ratio: String
        var phoneText: String
        var patientRef: String
        var windowDays: String
        var approvedText: String
        var statusLabel: String

        init(codeText: String, label: String, externalRefText: String, regionText: String, ratio: String, phoneText: String, patientRef: String, windowDays: String, approvedText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.externalRefText = externalRefText
            self.regionText = regionText
            self.ratio = ratio
            self.phoneText = phoneText
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRoundingCheckpointView(_ item: RegionalRoundingCheckpoint) -> RegionalRoundingCheckpointView {
        return RegionalRoundingCheckpointView(
            codeText: item.code,
            label: item.label,
            externalRefText: item.externalRef,
            regionText: item.region,
            ratio: String(format: "%.2f", item.ratio),
            phoneText: Kit.Text.truncate(item.phone, limit: 64),
            patientRef: item.patientRef,
            windowDays: String(item.windowDays),
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRoundingCheckpointViews(_ items: [RegionalRoundingCheckpoint]) -> [RegionalRoundingCheckpointView] {
        var views: [RegionalRoundingCheckpointView] = []
        for item in items {
            views.append(toRegionalRoundingCheckpointView(item))
        }
        return views
    }

    static func sumRegionalRoundingCheckpointView(_ view: RegionalRoundingCheckpointView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedRatio + Double(parsedWindowDays)
    }
}
