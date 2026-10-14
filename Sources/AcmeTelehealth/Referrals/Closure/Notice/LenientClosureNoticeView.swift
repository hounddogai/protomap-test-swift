import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient closure notice.
    final class LenientClosureNoticeView {
        var codeText: String
        var titleText: String
        var procedureCode: String
        var graceDays: String
        var reviewer: String
        var ownerIDText: String
        var checksum: String
        var statusLabel: String

        init(codeText: String, titleText: String, procedureCode: String, graceDays: String, reviewer: String, ownerIDText: String, checksum: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.procedureCode = procedureCode
            self.graceDays = graceDays
            self.reviewer = reviewer
            self.ownerIDText = ownerIDText
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toLenientClosureNoticeView(_ item: LenientClosureNotice) -> LenientClosureNoticeView {
        return LenientClosureNoticeView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            procedureCode: item.procedureCode,
            graceDays: String(item.graceDays),
            reviewer: item.reviewer,
            ownerIDText: item.ownerID,
            checksum: Kit.Text.truncate(item.checksum, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientClosureNoticeViews(_ items: [LenientClosureNotice]) -> [LenientClosureNoticeView] {
        var views: [LenientClosureNoticeView] = []
        for item in items {
            views.append(toLenientClosureNoticeView(item))
        }
        return views
    }

    static func sumLenientClosureNoticeView(_ view: LenientClosureNoticeView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
