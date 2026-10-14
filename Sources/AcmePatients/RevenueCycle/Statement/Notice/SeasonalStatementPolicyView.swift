import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a seasonal statement policy.
    final class SeasonalStatementPolicyView {
        var code: String
        var name: String
        var procedureCode: String
        var patientRef: String
        var batchSize: String
        var activeText: String
        var refills: String
        var archived: String
        var segmentText: String
        var approved: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, name: String, procedureCode: String, patientRef: String, batchSize: String, activeText: String, refills: String, archived: String, segmentText: String, approved: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.activeText = activeText
            self.refills = refills
            self.archived = archived
            self.segmentText = segmentText
            self.approved = approved
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalStatementPolicyView(_ item: SeasonalStatementPolicy) -> SeasonalStatementPolicyView {
        return SeasonalStatementPolicyView(
            code: item.code,
            name: item.name,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            batchSize: String(item.batchSize),
            activeText: "\(item.active)",
            refills: String(item.refills),
            archived: "\(item.archived)",
            segmentText: item.segment,
            approved: "\(item.approved)",
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalStatementPolicyViews(_ items: [SeasonalStatementPolicy]) -> [SeasonalStatementPolicyView] {
        var views: [SeasonalStatementPolicyView] = []
        for item in items {
            views.append(toSeasonalStatementPolicyView(item))
        }
        return views
    }

    static func sumSeasonalStatementPolicyView(_ view: SeasonalStatementPolicyView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedRefills)
    }
}
