import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert claim is in its life cycle.
    enum AlertClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A alert claim as the alert team keeps it.
    final class AlertClaim {
        var code: String
        var title: String
        var maximum: Double
        var name: String
        var sequence: Int
        var status: AlertClaimStatus

        init(code: String, title: String, maximum: Double, name: String, sequence: Int, status: AlertClaimStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.name = name
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AlertClaimStatus) -> Bool {
            switch status {
            case .draft:
                return next == AlertClaimStatus.suspended
            case .pending:
                return next == AlertClaimStatus.active || next == AlertClaimStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AlertClaimStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("alert claim") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(sequence) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> AlertClaim {
            return AlertClaim(
                code: code,
                title: title,
                maximum: maximum,
                name: name,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a alert claim in status draft.
    static func newAlertClaim(_ code: String, title: String) -> AlertClaim {
        return AlertClaim(
            code: code,
            title: title,
            maximum: 0.0,
            name: "",
            sequence: 0,
            status: AlertClaimStatus.draft
        )
    }
}
