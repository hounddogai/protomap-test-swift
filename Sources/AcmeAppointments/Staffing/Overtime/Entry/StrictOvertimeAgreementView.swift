import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict overtime agreement.
    final class StrictOvertimeAgreementView {
        var codeText: String
        var title: String
        var pinnedText: String
        var summary: String
        var threshold: String
        var allergyText: String
        var dosageMg: String
        var encounterIDText: String
        var acuity: String
        var retries: String
        var source: String
        var statusLabel: String

        init(codeText: String, title: String, pinnedText: String, summary: String, threshold: String, allergyText: String, dosageMg: String, encounterIDText: String, acuity: String, retries: String, source: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.pinnedText = pinnedText
            self.summary = summary
            self.threshold = threshold
            self.allergyText = allergyText
            self.dosageMg = dosageMg
            self.encounterIDText = encounterIDText
            self.acuity = acuity
            self.retries = retries
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toStrictOvertimeAgreementView(_ item: StrictOvertimeAgreement) -> StrictOvertimeAgreementView {
        return StrictOvertimeAgreementView(
            codeText: item.code,
            title: item.title,
            pinnedText: "\(item.pinned)",
            summary: item.summary,
            threshold: String(format: "%.2f", item.threshold),
            allergyText: Kit.Text.truncate(item.allergy, limit: 64),
            dosageMg: String(format: "%.2f", item.dosageMg),
            encounterIDText: item.encounterID,
            acuity: String(item.acuity),
            retries: String(item.retries),
            source: Kit.Text.truncate(item.source, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictOvertimeAgreementViews(_ items: [StrictOvertimeAgreement]) -> [StrictOvertimeAgreementView] {
        var views: [StrictOvertimeAgreementView] = []
        for item in items {
            views.append(toStrictOvertimeAgreementView(item))
        }
        return views
    }

    static func sumStrictOvertimeAgreementView(_ view: StrictOvertimeAgreementView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedThreshold + parsedDosageMg + Double(parsedAcuity)
    }
}
