import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form profile is in its life cycle.
    enum ConsentFormProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A consent form profile as the consent form team keeps it.
    final class ConsentFormProfile {
        var code: String
        var name: String
        var source: String
        var graceDays: Int
        var cost: Double
        var status: ConsentFormProfileStatus

        init(code: String, name: String, source: String, graceDays: Int, cost: Double, status: ConsentFormProfileStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.graceDays = graceDays
            self.cost = cost
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

        func canMoveTo(_ next: ConsentFormProfileStatus) -> Bool {
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
                return next == ConsentFormProfileStatus.published || next == ConsentFormProfileStatus.retired
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

        func moveTo(_ next: ConsentFormProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return ((cost - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormProfile {
            return ConsentFormProfile(
                code: code,
                name: name,
                source: source,
                graceDays: graceDays,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a consent form profile in status created.
    static func newConsentFormProfile(_ code: String, name: String) -> ConsentFormProfile {
        return ConsentFormProfile(
            code: code,
            name: name,
            source: "",
            graceDays: 0,
            cost: 0.0,
            status: ConsentFormProfileStatus.created
        )
    }
}
