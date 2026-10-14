import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional reference range profile.
    final class RegionalReferenceRangeProfileView {
        var codeText: String
        var label: String
        var reviewer: String
        var revision: String
        var durationMinutesText: String
        var procedureCodeText: String
        var statusLabel: String

        init(codeText: String, label: String, reviewer: String, revision: String, durationMinutesText: String, procedureCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.reviewer = reviewer
            self.revision = revision
            self.durationMinutesText = durationMinutesText
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalReferenceRangeProfileView(_ item: RegionalReferenceRangeProfile) -> RegionalReferenceRangeProfileView {
        return RegionalReferenceRangeProfileView(
            codeText: item.code,
            label: item.label,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            revision: String(item.revision),
            durationMinutesText: String(item.durationMinutes),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalReferenceRangeProfileViews(_ items: [RegionalReferenceRangeProfile]) -> [RegionalReferenceRangeProfileView] {
        var views: [RegionalReferenceRangeProfileView] = []
        for item in items {
            views.append(toRegionalReferenceRangeProfileView(item))
        }
        return views
    }

    static func sumRegionalReferenceRangeProfileView(_ view: RegionalReferenceRangeProfileView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedRevision) + Double(parsedDurationMinutes)
    }
}
