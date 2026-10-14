import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped dispense review is in its life cycle.
    enum CappedDispenseReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped dispense review. Its code is unique within a tenant.
    final class CappedDispenseReview {
        var code: String
        var label: String
        var diagnosisCode: String
        var name: String
        var checksum: String
        var notes: String
        var channel: String
        var priority: Int
        var status: CappedDispenseReviewStatus

        init(code: String, label: String, diagnosisCode: String, name: String, checksum: String, notes: String, channel: String, priority: Int, status: CappedDispenseReviewStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.name = name
            self.checksum = checksum
            self.notes = notes
            self.channel = channel
            self.priority = priority
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

        func canMoveTo(_ next: CappedDispenseReviewStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CappedDispenseReviewStatus.approved || next == CappedDispenseReviewStatus.withdrawn
            case .approved:
                return next == CappedDispenseReviewStatus.rejected
            case .rejected:
                return next == CappedDispenseReviewStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedDispenseReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped dispense review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> CappedDispenseReview {
            return CappedDispenseReview(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                name: name,
                checksum: checksum,
                notes: notes,
                channel: channel,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped dispense review in status proposed.
    static func newCappedDispenseReview(_ code: String, label: String) -> CappedDispenseReview {
        return CappedDispenseReview(
            code: code,
            label: label,
            diagnosisCode: "",
            name: "",
            checksum: "",
            notes: "",
            channel: "",
            priority: 0,
            status: CappedDispenseReviewStatus.proposed
        )
    }
}
