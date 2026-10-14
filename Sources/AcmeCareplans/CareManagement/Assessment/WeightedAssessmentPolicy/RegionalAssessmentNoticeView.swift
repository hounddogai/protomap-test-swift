import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a regional assessment notice.
    final class RegionalAssessmentNoticeView {
        var code: String
        var label: String
        var revision: String
        var dosageMg: String
        var retriesText: String
        var facility: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, label: String, revision: String, dosageMg: String, retriesText: String, facility: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.revision = revision
            self.dosageMg = dosageMg
            self.retriesText = retriesText
            self.facility = facility
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAssessmentNoticeView(_ item: RegionalAssessmentNotice) -> RegionalAssessmentNoticeView {
        return RegionalAssessmentNoticeView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            revision: String(item.revision),
            dosageMg: String(format: "%.2f", item.dosageMg),
            retriesText: String(item.retries),
            facility: Kit.Text.truncate(item.facility, limit: 80),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAssessmentNoticeViews(_ items: [RegionalAssessmentNotice]) -> [RegionalAssessmentNoticeView] {
        var views: [RegionalAssessmentNoticeView] = []
        for item in items {
            views.append(toRegionalAssessmentNoticeView(item))
        }
        return views
    }

    static func sumRegionalAssessmentNoticeView(_ view: RegionalAssessmentNoticeView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRevision) + parsedDosageMg + Double(parsedRetries)
    }
}
