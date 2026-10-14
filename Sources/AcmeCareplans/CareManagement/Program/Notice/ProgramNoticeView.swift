import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program notice.
    final class ProgramNoticeView {
        var codeText: String
        var title: String
        var maximum: String
        var wardText: String
        var rate: String
        var statusLabel: String

        init(codeText: String, title: String, maximum: String, wardText: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.maximum = maximum
            self.wardText = wardText
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toProgramNoticeView(_ item: ProgramNotice) -> ProgramNoticeView {
        return ProgramNoticeView(
            codeText: item.code,
            title: item.title,
            maximum: String(format: "%.2f", item.maximum),
            wardText: Kit.Text.truncate(item.ward, limit: 40),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramNoticeViews(_ items: [ProgramNotice]) -> [ProgramNoticeView] {
        var views: [ProgramNoticeView] = []
        for item in items {
            views.append(toProgramNoticeView(item))
        }
        return views
    }

    static func sumProgramNoticeView(_ view: ProgramNoticeView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedMaximum + parsedRate
    }
}
