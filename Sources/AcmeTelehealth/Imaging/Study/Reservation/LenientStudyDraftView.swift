import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient study draft.
    final class LenientStudyDraftView {
        var code: String
        var title: String
        var ratioText: String
        var region: String
        var diagnosisCode: String
        var revision: String
        var checksumText: String
        var visitMinutesText: String
        var statusLabel: String

        init(code: String, title: String, ratioText: String, region: String, diagnosisCode: String, revision: String, checksumText: String, visitMinutesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ratioText = ratioText
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.revision = revision
            self.checksumText = checksumText
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientStudyDraftView(_ item: LenientStudyDraft) -> LenientStudyDraftView {
        return LenientStudyDraftView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 120),
            ratioText: String(format: "%.2f", item.ratio),
            region: item.region,
            diagnosisCode: item.diagnosisCode,
            revision: String(item.revision),
            checksumText: item.checksum,
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientStudyDraftViews(_ items: [LenientStudyDraft]) -> [LenientStudyDraftView] {
        var views: [LenientStudyDraftView] = []
        for item in items {
            views.append(toLenientStudyDraftView(item))
        }
        return views
    }

    static func sumLenientStudyDraftView(_ view: LenientStudyDraftView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedRatio + Double(parsedRevision) + Double(parsedVisitMinutes)
    }
}
