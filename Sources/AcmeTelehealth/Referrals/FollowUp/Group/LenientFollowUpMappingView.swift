import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient follow up mapping.
    final class LenientFollowUpMappingView {
        var code: String
        var label: String
        var windowDaysText: String
        var diagnosisCodeText: String
        var ratioText: String
        var statusLabel: String

        init(code: String, label: String, windowDaysText: String, diagnosisCodeText: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.windowDaysText = windowDaysText
            self.diagnosisCodeText = diagnosisCodeText
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientFollowUpMappingView(_ item: LenientFollowUpMapping) -> LenientFollowUpMappingView {
        return LenientFollowUpMappingView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            windowDaysText: String(item.windowDays),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientFollowUpMappingViews(_ items: [LenientFollowUpMapping]) -> [LenientFollowUpMappingView] {
        var views: [LenientFollowUpMappingView] = []
        for item in items {
            views.append(toLenientFollowUpMappingView(item))
        }
        return views
    }

    static func sumLenientFollowUpMappingView(_ view: LenientFollowUpMappingView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedWindowDays) + parsedRatio
    }
}
