import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling referral exception is in its life cycle.
    enum RollingReferralExceptionStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling referral exception. Its code is unique within a tenant.
    final class RollingReferralException {
        var code: String
        var label: String
        var name: String
        var floorValue: Double
        var archived: Bool
        var weight: Double
        var revision: Int
        var externalRef: String
        var limit: Int
        var status: RollingReferralExceptionStatus

        init(code: String, label: String, name: String, floorValue: Double, archived: Bool, weight: Double, revision: Int, externalRef: String, limit: Int, status: RollingReferralExceptionStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.floorValue = floorValue
            self.archived = archived
            self.weight = weight
            self.revision = revision
            self.externalRef = externalRef
            self.limit = limit
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

        func canMoveTo(_ next: RollingReferralExceptionStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RollingReferralExceptionStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingReferralExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling referral exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedExposure() -> Double {
            return ((floorValue - weight) * 100).rounded() / 100
        }

        func copyValue() -> RollingReferralException {
            return RollingReferralException(
                code: code,
                label: label,
                name: name,
                floorValue: floorValue,
                archived: archived,
                weight: weight,
                revision: revision,
                externalRef: externalRef,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling referral exception in status planned.
    static func newRollingReferralException(_ code: String, label: String) -> RollingReferralException {
        return RollingReferralException(
            code: code,
            label: label,
            name: "",
            floorValue: 0.0,
            archived: false,
            weight: 0.0,
            revision: 0,
            externalRef: "",
            limit: 0,
            status: RollingReferralExceptionStatus.planned
        )
    }
}
