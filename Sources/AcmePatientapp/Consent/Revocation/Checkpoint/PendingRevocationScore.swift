import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending revocation score is in its life cycle.
    enum PendingRevocationScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A pending revocation score. Its code is unique within a tenant.
    final class PendingRevocationScore {
        var code: String
        var label: String
        var copay: Double
        var priority: Int
        var graceDays: Int
        var ceiling: Double
        var approved: Bool
        var payer: String
        var status: PendingRevocationScoreStatus

        init(code: String, label: String, copay: Double, priority: Int, graceDays: Int, ceiling: Double, approved: Bool, payer: String, status: PendingRevocationScoreStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.priority = priority
            self.graceDays = graceDays
            self.ceiling = ceiling
            self.approved = approved
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingRevocationScoreStatus) -> Bool {
            switch status {
            case .created:
                return next == PendingRevocationScoreStatus.published || next == PendingRevocationScoreStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PendingRevocationScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending revocation score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netLoad() -> Double {
            return ((ceiling + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> PendingRevocationScore {
            return PendingRevocationScore(
                code: code,
                label: label,
                copay: copay,
                priority: priority,
                graceDays: graceDays,
                ceiling: ceiling,
                approved: approved,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending revocation score in status created.
    static func newPendingRevocationScore(_ code: String, label: String) -> PendingRevocationScore {
        return PendingRevocationScore(
            code: code,
            label: label,
            copay: 0.0,
            priority: 0,
            graceDays: 0,
            ceiling: 0.0,
            approved: false,
            payer: "",
            status: PendingRevocationScoreStatus.created
        )
    }
}
