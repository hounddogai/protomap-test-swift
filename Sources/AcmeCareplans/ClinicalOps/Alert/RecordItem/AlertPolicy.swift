import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert policy is in its life cycle.
    enum AlertPolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a alert policy and its current status.
    final class AlertPolicy {
        var code: String
        var name: String
        var expiresAt: Int
        var procedureCode: String
        var rate: Double
        var status: AlertPolicyStatus

        init(code: String, name: String, expiresAt: Int, procedureCode: String, rate: Double, status: AlertPolicyStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.procedureCode = procedureCode
            self.rate = rate
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

        func canMoveTo(_ next: AlertPolicyStatus) -> Bool {
            switch status {
            case .idle:
                return next == AlertPolicyStatus.draining || next == AlertPolicyStatus.stopped
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == AlertPolicyStatus.draining || next == AlertPolicyStatus.stopped
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

        func moveTo(_ next: AlertPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedVolume() -> Double {
            return ((Double(expiresAt) - rate) * 100).rounded() / 100
        }

        func copyValue() -> AlertPolicy {
            return AlertPolicy(
                code: code,
                name: name,
                expiresAt: expiresAt,
                procedureCode: procedureCode,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a alert policy in status idle.
    static func newAlertPolicy(_ code: String, name: String) -> AlertPolicy {
        return AlertPolicy(
            code: code,
            name: name,
            expiresAt: 0,
            procedureCode: "",
            rate: 0.0,
            status: AlertPolicyStatus.idle
        )
    }
}
