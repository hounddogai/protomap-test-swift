import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense agreement is in its life cycle.
    enum DispenseAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A dispense agreement as the dispense team keeps it.
    final class DispenseAgreement {
        var code: String
        var label: String
        var active: Bool
        var updatedAt: Int
        var ratio: Double
        var attempts: Int
        var status: DispenseAgreementStatus

        init(code: String, label: String, active: Bool, updatedAt: Int, ratio: Double, attempts: Int, status: DispenseAgreementStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.updatedAt = updatedAt
            self.ratio = ratio
            self.attempts = attempts
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

        func canMoveTo(_ next: DispenseAgreementStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DispenseAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedExposure() -> Double {
            return ((Double(updatedAt) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseAgreement {
            return DispenseAgreement(
                code: code,
                label: label,
                active: active,
                updatedAt: updatedAt,
                ratio: ratio,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a dispense agreement in status created.
    static func newDispenseAgreement(_ code: String, label: String) -> DispenseAgreement {
        return DispenseAgreement(
            code: code,
            label: label,
            active: false,
            updatedAt: 0,
            ratio: 0.0,
            attempts: 0,
            status: DispenseAgreementStatus.created
        )
    }
}
