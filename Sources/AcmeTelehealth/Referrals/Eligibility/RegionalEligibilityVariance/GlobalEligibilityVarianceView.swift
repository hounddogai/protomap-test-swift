import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global eligibility variance.
    final class GlobalEligibilityVarianceView {
        var code: String
        var title: String
        var floorValue: String
        var refills: String
        var sequence: String
        var clinicianIDText: String
        var windowDaysText: String
        var margin: String
        var pinned: String
        var retries: String
        var approvedText: String
        var statusLabel: String

        init(code: String, title: String, floorValue: String, refills: String, sequence: String, clinicianIDText: String, windowDaysText: String, margin: String, pinned: String, retries: String, approvedText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.refills = refills
            self.sequence = sequence
            self.clinicianIDText = clinicianIDText
            self.windowDaysText = windowDaysText
            self.margin = margin
            self.pinned = pinned
            self.retries = retries
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalEligibilityVarianceView(_ item: GlobalEligibilityVariance) -> GlobalEligibilityVarianceView {
        return GlobalEligibilityVarianceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 120),
            floorValue: String(format: "%.2f", item.floorValue),
            refills: String(item.refills),
            sequence: String(item.sequence),
            clinicianIDText: item.clinicianID,
            windowDaysText: String(item.windowDays),
            margin: String(format: "%.2f", item.margin),
            pinned: "\(item.pinned)",
            retries: String(item.retries),
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalEligibilityVarianceViews(_ items: [GlobalEligibilityVariance]) -> [GlobalEligibilityVarianceView] {
        var views: [GlobalEligibilityVarianceView] = []
        for item in items {
            views.append(toGlobalEligibilityVarianceView(item))
        }
        return views
    }

    static func sumGlobalEligibilityVarianceView(_ view: GlobalEligibilityVarianceView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedFloorValue + Double(parsedRefills) + Double(parsedSequence)
    }
}
