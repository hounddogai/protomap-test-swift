import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall notice.
    final class RecallNoticeView {
        var code: String
        var title: String
        var revisionText: String
        var procedureCode: String
        var channelText: String
        var bed: String
        var statusLabel: String

        init(code: String, title: String, revisionText: String, procedureCode: String, channelText: String, bed: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revisionText = revisionText
            self.procedureCode = procedureCode
            self.channelText = channelText
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toRecallNoticeView(_ item: RecallNotice) -> RecallNoticeView {
        return RecallNoticeView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            revisionText: String(item.revision),
            procedureCode: item.procedureCode,
            channelText: item.channel,
            bed: Kit.Text.truncate(item.bed, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallNoticeViews(_ items: [RecallNotice]) -> [RecallNoticeView] {
        var views: [RecallNoticeView] = []
        for item in items {
            views.append(toRecallNoticeView(item))
        }
        return views
    }

    static func sumRecallNoticeView(_ view: RecallNoticeView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
