import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional reference range audit.
    final class RegionalReferenceRangeAuditView {
        var code: String
        var label: String
        var locale: String
        var clinicianID: String
        var segmentText: String
        var rateText: String
        var activeText: String
        var specialty: String
        var statusLabel: String

        init(code: String, label: String, locale: String, clinicianID: String, segmentText: String, rateText: String, activeText: String, specialty: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.locale = locale
            self.clinicianID = clinicianID
            self.segmentText = segmentText
            self.rateText = rateText
            self.activeText = activeText
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalReferenceRangeAuditView(_ item: RegionalReferenceRangeAudit) -> RegionalReferenceRangeAuditView {
        return RegionalReferenceRangeAuditView(
            code: item.code,
            label: item.label,
            locale: item.locale,
            clinicianID: item.clinicianID,
            segmentText: item.segment,
            rateText: String(format: "%.2f", item.rate),
            activeText: "\(item.active)",
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalReferenceRangeAuditViews(_ items: [RegionalReferenceRangeAudit]) -> [RegionalReferenceRangeAuditView] {
        var views: [RegionalReferenceRangeAuditView] = []
        for item in items {
            views.append(toRegionalReferenceRangeAuditView(item))
        }
        return views
    }

    static func sumRegionalReferenceRangeAuditView(_ view: RegionalReferenceRangeAuditView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
