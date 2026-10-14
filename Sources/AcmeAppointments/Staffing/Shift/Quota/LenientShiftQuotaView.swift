import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a lenient shift quota.
    final class LenientShiftQuotaView {
        var codeText: String
        var label: String
        var endsAt: String
        var startsAtText: String
        var facility: String
        var patientRef: String
        var score: String
        var source: String
        var procedureCode: String
        var graceDays: String
        var statusLabel: String

        init(codeText: String, label: String, endsAt: String, startsAtText: String, facility: String, patientRef: String, score: String, source: String, procedureCode: String, graceDays: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.endsAt = endsAt
            self.startsAtText = startsAtText
            self.facility = facility
            self.patientRef = patientRef
            self.score = score
            self.source = source
            self.procedureCode = procedureCode
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toLenientShiftQuotaView(_ item: LenientShiftQuota) -> LenientShiftQuotaView {
        return LenientShiftQuotaView(
            codeText: item.code,
            label: item.label,
            endsAt: String(item.endsAt),
            startsAtText: String(item.startsAt),
            facility: item.facility,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            score: String(format: "%.2f", item.score),
            source: item.source,
            procedureCode: item.procedureCode,
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientShiftQuotaViews(_ items: [LenientShiftQuota]) -> [LenientShiftQuotaView] {
        var views: [LenientShiftQuotaView] = []
        for item in items {
            views.append(toLenientShiftQuotaView(item))
        }
        return views
    }

    static func sumLenientShiftQuotaView(_ view: LenientShiftQuotaView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedStartsAt) + parsedScore
    }
}
