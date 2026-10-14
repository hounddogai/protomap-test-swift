import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled revocation review is in its life cycle.
    enum ScheduledRevocationReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled revocation review. Its code is unique within a tenant.
    final class ScheduledRevocationReview {
        var code: String
        var name: String
        var ceiling: Double
        var label: String
        var procedureCode: String
        var status: ScheduledRevocationReviewStatus

        init(code: String, name: String, ceiling: Double, label: String, procedureCode: String, status: ScheduledRevocationReviewStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.label = label
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledRevocationReviewStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledRevocationReviewStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ScheduledRevocationReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled revocation review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> ScheduledRevocationReview {
            return ScheduledRevocationReview(
                code: code,
                name: name,
                ceiling: ceiling,
                label: label,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled revocation review in status requested.
    static func newScheduledRevocationReview(_ code: String, name: String) -> ScheduledRevocationReview {
        return ScheduledRevocationReview(
            code: code,
            name: name,
            ceiling: 0.0,
            label: "",
            procedureCode: "",
            status: ScheduledRevocationReviewStatus.requested
        )
    }
}
