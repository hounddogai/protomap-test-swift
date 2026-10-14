import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility record.
    final class EligibilityRecordView {
        var code: String
        var title: String
        var externalRefText: String
        var revision: String
        var checksum: String
        var batchSize: String
        var statusLabel: String

        init(code: String, title: String, externalRefText: String, revision: String, checksum: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRefText = externalRefText
            self.revision = revision
            self.checksum = checksum
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityRecordView(_ item: EligibilityRecord) -> EligibilityRecordView {
        return EligibilityRecordView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 80),
            externalRefText: item.externalRef,
            revision: String(item.revision),
            checksum: item.checksum,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityRecordViews(_ items: [EligibilityRecord]) -> [EligibilityRecordView] {
        var views: [EligibilityRecordView] = []
        for item in items {
            views.append(toEligibilityRecordView(item))
        }
        return views
    }

    static func sumEligibilityRecordView(_ view: EligibilityRecordView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedRevision) + Double(parsedBatchSize)
    }
}
