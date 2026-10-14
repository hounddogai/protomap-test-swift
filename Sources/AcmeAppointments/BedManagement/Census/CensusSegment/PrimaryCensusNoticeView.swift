import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary census notice.
    final class PrimaryCensusNoticeView {
        var codeText: String
        var label: String
        var visitMinutes: String
        var copay: String
        var ownerID: String
        var reviewer: String
        var activeText: String
        var description: String
        var statusLabel: String

        init(codeText: String, label: String, visitMinutes: String, copay: String, ownerID: String, reviewer: String, activeText: String, description: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.ownerID = ownerID
            self.reviewer = reviewer
            self.activeText = activeText
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCensusNoticeView(_ item: PrimaryCensusNotice) -> PrimaryCensusNoticeView {
        return PrimaryCensusNoticeView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 80),
            visitMinutes: String(item.visitMinutes),
            copay: String(format: "%.2f", item.copay),
            ownerID: item.ownerID,
            reviewer: item.reviewer,
            activeText: "\(item.active)",
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCensusNoticeViews(_ items: [PrimaryCensusNotice]) -> [PrimaryCensusNoticeView] {
        var views: [PrimaryCensusNoticeView] = []
        for item in items {
            views.append(toPrimaryCensusNoticeView(item))
        }
        return views
    }

    static func sumPrimaryCensusNoticeView(_ view: PrimaryCensusNoticeView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCopay
    }
}
