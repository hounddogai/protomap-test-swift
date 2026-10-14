import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy courier cycle.
    final class LegacyCourierCycleView {
        var codeText: String
        var title: String
        var phoneText: String
        var clinicianID: String
        var batchSize: String
        var active: String
        var revision: String
        var statusLabel: String

        init(codeText: String, title: String, phoneText: String, clinicianID: String, batchSize: String, active: String, revision: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.phoneText = phoneText
            self.clinicianID = clinicianID
            self.batchSize = batchSize
            self.active = active
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCourierCycleView(_ item: LegacyCourierCycle) -> LegacyCourierCycleView {
        return LegacyCourierCycleView(
            codeText: item.code,
            title: item.title,
            phoneText: Kit.Text.truncate(item.phone, limit: 40),
            clinicianID: item.clinicianID,
            batchSize: String(item.batchSize),
            active: "\(item.active)",
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCourierCycleViews(_ items: [LegacyCourierCycle]) -> [LegacyCourierCycleView] {
        var views: [LegacyCourierCycleView] = []
        for item in items {
            views.append(toLegacyCourierCycleView(item))
        }
        return views
    }

    static func sumLegacyCourierCycleView(_ view: LegacyCourierCycleView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedRevision)
    }
}
