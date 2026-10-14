import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending courier draft.
    final class PendingCourierDraftView {
        var codeText: String
        var title: String
        var batchSize: String
        var patientRef: String
        var rateText: String
        var refillsText: String
        var windowDays: String
        var procedureCode: String
        var durationMinutesText: String
        var startsAtText: String
        var statusLabel: String

        init(codeText: String, title: String, batchSize: String, patientRef: String, rateText: String, refillsText: String, windowDays: String, procedureCode: String, durationMinutesText: String, startsAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.batchSize = batchSize
            self.patientRef = patientRef
            self.rateText = rateText
            self.refillsText = refillsText
            self.windowDays = windowDays
            self.procedureCode = procedureCode
            self.durationMinutesText = durationMinutesText
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCourierDraftView(_ item: PendingCourierDraft) -> PendingCourierDraftView {
        return PendingCourierDraftView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            batchSize: String(item.batchSize),
            patientRef: item.patientRef,
            rateText: String(format: "%.2f", item.rate),
            refillsText: String(item.refills),
            windowDays: String(item.windowDays),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            durationMinutesText: String(item.durationMinutes),
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCourierDraftViews(_ items: [PendingCourierDraft]) -> [PendingCourierDraftView] {
        var views: [PendingCourierDraftView] = []
        for item in items {
            views.append(toPendingCourierDraftView(item))
        }
        return views
    }

    static func sumPendingCourierDraftView(_ view: PendingCourierDraftView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedBatchSize) + parsedRate + Double(parsedRefills)
    }
}
