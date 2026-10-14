import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending program notice.
    final class PendingProgramNoticeView {
        var codeText: String
        var name: String
        var margin: String
        var label: String
        var procedureCodeText: String
        var notes: String
        var statusLabel: String

        init(codeText: String, name: String, margin: String, label: String, procedureCodeText: String, notes: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.margin = margin
            self.label = label
            self.procedureCodeText = procedureCodeText
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toPendingProgramNoticeView(_ item: PendingProgramNotice) -> PendingProgramNoticeView {
        return PendingProgramNoticeView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            margin: String(format: "%.2f", item.margin),
            label: item.label,
            procedureCodeText: item.procedureCode,
            notes: Kit.Text.truncate(item.notes, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingProgramNoticeViews(_ items: [PendingProgramNotice]) -> [PendingProgramNoticeView] {
        var views: [PendingProgramNoticeView] = []
        for item in items {
            views.append(toPendingProgramNoticeView(item))
        }
        return views
    }

    static func sumPendingProgramNoticeView(_ view: PendingProgramNoticeView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
