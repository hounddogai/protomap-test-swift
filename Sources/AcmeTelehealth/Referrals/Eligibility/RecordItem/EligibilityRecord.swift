import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility record is in its life cycle.
    enum EligibilityRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One eligibility record, with what the planners need to act on it.
    final class EligibilityRecord {
        var code: String
        var title: String
        var externalRef: String
        var revision: Int
        var checksum: String
        var batchSize: Int
        var status: EligibilityRecordStatus

        init(code: String, title: String, externalRef: String, revision: Int, checksum: String, batchSize: Int, status: EligibilityRecordStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.revision = revision
            self.checksum = checksum
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: EligibilityRecordStatus) -> Bool {
            switch status {
            case .proposed:
                return next == EligibilityRecordStatus.approved
            case .approved:
                return next == EligibilityRecordStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedExposure() -> Double {
            return ((Double(revision) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityRecord {
            return EligibilityRecord(
                code: code,
                title: title,
                externalRef: externalRef,
                revision: revision,
                checksum: checksum,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a eligibility record in status proposed.
    static func newEligibilityRecord(_ code: String, title: String) -> EligibilityRecord {
        return EligibilityRecord(
            code: code,
            title: title,
            externalRef: "",
            revision: 0,
            checksum: "",
            batchSize: 0,
            status: EligibilityRecordStatus.proposed
        )
    }
}
