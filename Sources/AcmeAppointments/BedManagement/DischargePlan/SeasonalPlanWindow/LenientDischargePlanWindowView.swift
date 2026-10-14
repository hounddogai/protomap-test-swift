import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient discharge plan window.
    final class LenientDischargePlanWindowView {
        var code: String
        var nameText: String
        var pinned: String
        var windowDays: String
        var label: String
        var diagnosisCode: String
        var visible: String
        var threshold: String
        var country: String
        var statusLabel: String

        init(code: String, nameText: String, pinned: String, windowDays: String, label: String, diagnosisCode: String, visible: String, threshold: String, country: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.pinned = pinned
            self.windowDays = windowDays
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.visible = visible
            self.threshold = threshold
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toLenientDischargePlanWindowView(_ item: LenientDischargePlanWindow) -> LenientDischargePlanWindowView {
        return LenientDischargePlanWindowView(
            code: item.code,
            nameText: item.name,
            pinned: "\(item.pinned)",
            windowDays: String(item.windowDays),
            label: Kit.Text.truncate(item.label, limit: 120),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            visible: "\(item.visible)",
            threshold: String(format: "%.2f", item.threshold),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientDischargePlanWindowViews(_ items: [LenientDischargePlanWindow]) -> [LenientDischargePlanWindowView] {
        var views: [LenientDischargePlanWindowView] = []
        for item in items {
            views.append(toLenientDischargePlanWindowView(item))
        }
        return views
    }

    static func sumLenientDischargePlanWindowView(_ view: LenientDischargePlanWindowView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedWindowDays) + parsedThreshold
    }
}
