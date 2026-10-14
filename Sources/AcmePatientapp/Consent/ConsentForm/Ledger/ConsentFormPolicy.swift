import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form policy is in its life cycle.
    enum ConsentFormPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One consent form policy, with what the planners need to act on it.
    final class ConsentFormPolicy {
        var code: String
        var name: String
        var acuity: Int
        var dosageMg: Double
        var visitMinutes: Int
        var status: ConsentFormPolicyStatus

        init(code: String, name: String, acuity: Int, dosageMg: Double, visitMinutes: Int, status: ConsentFormPolicyStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormPolicyStatus) -> Bool {
            switch status {
            case .new:
                return next == ConsentFormPolicyStatus.queued || next == ConsentFormPolicyStatus.done
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ConsentFormPolicyStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ConsentFormPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("consent form policy") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(acuity) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormPolicy {
            return ConsentFormPolicy(
                code: code,
                name: name,
                acuity: acuity,
                dosageMg: dosageMg,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a consent form policy in status new.
    static func newConsentFormPolicy(_ code: String, name: String) -> ConsentFormPolicy {
        return ConsentFormPolicy(
            code: code,
            name: name,
            acuity: 0,
            dosageMg: 0.0,
            visitMinutes: 0,
            status: ConsentFormPolicyStatus.new
        )
    }
}
