import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default alert agreement is in its life cycle.
    enum DefaultAlertAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default alert agreement as the alert team keeps it.
    final class DefaultAlertAgreement {
        var code: String
        var label: String
        var amount: Double
        var approved: Bool
        var ratio: Double
        var status: DefaultAlertAgreementStatus

        init(code: String, label: String, amount: Double, approved: Bool, ratio: Double, status: DefaultAlertAgreementStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.approved = approved
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultAlertAgreementStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DefaultAlertAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default alert agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("default alert agreement") \(code)"
        }

        func adjustedValue() -> Double {
            return ((amount + ratio) * 100).rounded() / 100
        }

        func copyValue() -> DefaultAlertAgreement {
            return DefaultAlertAgreement(
                code: code,
                label: label,
                amount: amount,
                approved: approved,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default alert agreement in status idle.
    static func newDefaultAlertAgreement(_ code: String, label: String) -> DefaultAlertAgreement {
        return DefaultAlertAgreement(
            code: code,
            label: label,
            amount: 0.0,
            approved: false,
            ratio: 0.0,
            status: DefaultAlertAgreementStatus.idle
        )
    }
}
