import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority notice.
    final class PriorityNoticeView {
        var code: String
        var title: String
        var bed: String
        var sequence: String
        var retries: String
        var acuityText: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, title: String, bed: String, sequence: String, retries: String, acuityText: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.bed = bed
            self.sequence = sequence
            self.retries = retries
            self.acuityText = acuityText
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityNoticeView(_ item: PriorityNotice) -> PriorityNoticeView {
        return PriorityNoticeView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 40),
            bed: item.bed,
            sequence: String(item.sequence),
            retries: String(item.retries),
            acuityText: String(item.acuity),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityNoticeViews(_ items: [PriorityNotice]) -> [PriorityNoticeView] {
        var views: [PriorityNoticeView] = []
        for item in items {
            views.append(toPriorityNoticeView(item))
        }
        return views
    }

    static func sumPriorityNoticeView(_ view: PriorityNoticeView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedSequence) + Double(parsedRetries) + Double(parsedAcuity)
    }
}
