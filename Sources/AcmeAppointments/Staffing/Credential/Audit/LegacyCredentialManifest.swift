import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy credential manifest is in its life cycle.
    enum LegacyCredentialManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a legacy credential manifest and its current status.
    final class LegacyCredentialManifest {
        var code: String
        var title: String
        var region: String
        var retries: Int
        var batchSize: Int
        var score: Double
        var encounterID: String
        var facility: String
        var discount: Double
        var maximum: Double
        var dosageMg: Double
        var status: LegacyCredentialManifestStatus

        init(code: String, title: String, region: String, retries: Int, batchSize: Int, score: Double, encounterID: String, facility: String, discount: Double, maximum: Double, dosageMg: Double, status: LegacyCredentialManifestStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.retries = retries
            self.batchSize = batchSize
            self.score = score
            self.encounterID = encounterID
            self.facility = facility
            self.discount = discount
            self.maximum = maximum
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCredentialManifestStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyCredentialManifestStatus.scheduled
            case .scheduled:
                return next == LegacyCredentialManifestStatus.completed
            case .inProgress:
                return next == LegacyCredentialManifestStatus.completed
            case .completed:
                return next == LegacyCredentialManifestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyCredentialManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy credential manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy credential manifest") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((score - discount) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCredentialManifest {
            return LegacyCredentialManifest(
                code: code,
                title: title,
                region: region,
                retries: retries,
                batchSize: batchSize,
                score: score,
                encounterID: encounterID,
                facility: facility,
                discount: discount,
                maximum: maximum,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a legacy credential manifest in status planned.
    static func newLegacyCredentialManifest(_ code: String, title: String) -> LegacyCredentialManifest {
        return LegacyCredentialManifest(
            code: code,
            title: title,
            region: "",
            retries: 0,
            batchSize: 0,
            score: 0.0,
            encounterID: "",
            facility: "",
            discount: 0.0,
            maximum: 0.0,
            dosageMg: 0.0,
            status: LegacyCredentialManifestStatus.planned
        )
    }
}
