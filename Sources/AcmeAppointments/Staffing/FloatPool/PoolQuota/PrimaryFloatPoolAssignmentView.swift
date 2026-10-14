import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary float pool assignment.
    final class PrimaryFloatPoolAssignmentView {
        var code: String
        var labelText: String
        var archived: String
        var checksumText: String
        var bed: String
        var graceDaysText: String
        var statusLabel: String

        init(code: String, labelText: String, archived: String, checksumText: String, bed: String, graceDaysText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.archived = archived
            self.checksumText = checksumText
            self.bed = bed
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryFloatPoolAssignmentView(_ item: PrimaryFloatPoolAssignment) -> PrimaryFloatPoolAssignmentView {
        return PrimaryFloatPoolAssignmentView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            archived: "\(item.archived)",
            checksumText: item.checksum,
            bed: item.bed,
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryFloatPoolAssignmentViews(_ items: [PrimaryFloatPoolAssignment]) -> [PrimaryFloatPoolAssignmentView] {
        var views: [PrimaryFloatPoolAssignmentView] = []
        for item in items {
            views.append(toPrimaryFloatPoolAssignmentView(item))
        }
        return views
    }

    static func sumPrimaryFloatPoolAssignmentView(_ view: PrimaryFloatPoolAssignmentView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
