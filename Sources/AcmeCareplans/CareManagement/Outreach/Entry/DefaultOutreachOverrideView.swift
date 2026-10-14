import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default outreach override.
    final class DefaultOutreachOverrideView {
        var code: String
        var name: String
        var checksum: String
        var budget: String
        var timezone: String
        var revision: String
        var externalRef: String
        var segmentText: String
        var batchSize: String
        var statusLabel: String

        init(code: String, name: String, checksum: String, budget: String, timezone: String, revision: String, externalRef: String, segmentText: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.budget = budget
            self.timezone = timezone
            self.revision = revision
            self.externalRef = externalRef
            self.segmentText = segmentText
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultOutreachOverrideView(_ item: DefaultOutreachOverride) -> DefaultOutreachOverrideView {
        return DefaultOutreachOverrideView(
            code: item.code,
            name: item.name,
            checksum: item.checksum,
            budget: String(format: "%.2f", item.budget),
            timezone: item.timezone,
            revision: String(item.revision),
            externalRef: item.externalRef,
            segmentText: item.segment,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultOutreachOverrideViews(_ items: [DefaultOutreachOverride]) -> [DefaultOutreachOverrideView] {
        var views: [DefaultOutreachOverrideView] = []
        for item in items {
            views.append(toDefaultOutreachOverrideView(item))
        }
        return views
    }

    static func sumDefaultOutreachOverrideView(_ view: DefaultOutreachOverrideView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedBudget + Double(parsedRevision) + Double(parsedBatchSize)
    }
}
