import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential preference is in its life cycle.
    enum CredentialPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One credential preference, with what the planners need to act on it.
    final class CredentialPreference {
        var code: String
        var name: String
        var cost: Double
        var segment: String
        var amount: Double
        var status: CredentialPreferenceStatus

        init(code: String, name: String, cost: Double, segment: String, amount: Double, status: CredentialPreferenceStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.segment = segment
            self.amount = amount
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

        func canMoveTo(_ next: CredentialPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                return next == CredentialPreferenceStatus.ready || next == CredentialPreferenceStatus.stopped
            case .warming:
                return next == CredentialPreferenceStatus.ready || next == CredentialPreferenceStatus.draining
            case .ready:
                return next == CredentialPreferenceStatus.stopped
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

        func moveTo(_ next: CredentialPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("credential preference") \(code)"
        }

        func projectedTotal() -> Double {
            return (cost * amount * 100).rounded() / 100
        }

        func copyValue() -> CredentialPreference {
            return CredentialPreference(
                code: code,
                name: name,
                cost: cost,
                segment: segment,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a credential preference in status idle.
    static func newCredentialPreference(_ code: String, name: String) -> CredentialPreference {
        return CredentialPreference(
            code: code,
            name: name,
            cost: 0.0,
            segment: "",
            amount: 0.0,
            status: CredentialPreferenceStatus.idle
        )
    }
}
