import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a batched accession notice.
    final class BatchedAccessionNoticeView {
        var codeText: String
        var nameText: String
        var ceilingText: String
        var allergyText: String
        var notes: String
        var procedureCode: String
        var summary: String
        var checksum: String
        var refills: String
        var statusLabel: String

        init(codeText: String, nameText: String, ceilingText: String, allergyText: String, notes: String, procedureCode: String, summary: String, checksum: String, refills: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.ceilingText = ceilingText
            self.allergyText = allergyText
            self.notes = notes
            self.procedureCode = procedureCode
            self.summary = summary
            self.checksum = checksum
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedAccessionNoticeView(_ item: BatchedAccessionNotice) -> BatchedAccessionNoticeView {
        return BatchedAccessionNoticeView(
            codeText: item.code,
            nameText: item.name,
            ceilingText: String(format: "%.2f", item.ceiling),
            allergyText: Kit.Text.truncate(item.allergy, limit: 40),
            notes: item.notes,
            procedureCode: item.procedureCode,
            summary: item.summary,
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedAccessionNoticeViews(_ items: [BatchedAccessionNotice]) -> [BatchedAccessionNoticeView] {
        var views: [BatchedAccessionNoticeView] = []
        for item in items {
            views.append(toBatchedAccessionNoticeView(item))
        }
        return views
    }

    static func sumBatchedAccessionNoticeView(_ view: BatchedAccessionNoticeView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedCeiling + Double(parsedRefills)
    }
}
