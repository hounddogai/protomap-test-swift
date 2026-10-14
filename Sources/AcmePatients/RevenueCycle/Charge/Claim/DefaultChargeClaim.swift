import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default charge claim is in its life cycle.
    enum DefaultChargeClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One default charge claim, with what the planners need to act on it.
    final class DefaultChargeClaim {
        var code: String
        var name: String
        var threshold: Double
        var specialty: String
        var graceDays: Int
        var floorValue: Double
        var contactEmail: String
        var status: DefaultChargeClaimStatus

        init(code: String, name: String, threshold: Double, specialty: String, graceDays: Int, floorValue: Double, contactEmail: String, status: DefaultChargeClaimStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.specialty = specialty
            self.graceDays = graceDays
            self.floorValue = floorValue
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: DefaultChargeClaimStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultChargeClaimStatus.warming
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DefaultChargeClaimStatus.draining || next == DefaultChargeClaimStatus.stopped
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

        func moveTo(_ next: DefaultChargeClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default charge claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netLoad() -> Double {
            return (Double(graceDays) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> DefaultChargeClaim {
            return DefaultChargeClaim(
                code: code,
                name: name,
                threshold: threshold,
                specialty: specialty,
                graceDays: graceDays,
                floorValue: floorValue,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default charge claim in status idle.
    static func newDefaultChargeClaim(_ code: String, name: String) -> DefaultChargeClaim {
        return DefaultChargeClaim(
            code: code,
            name: name,
            threshold: 0.0,
            specialty: "",
            graceDays: 0,
            floorValue: 0.0,
            contactEmail: "",
            status: DefaultChargeClaimStatus.idle
        )
    }
}
