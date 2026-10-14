import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential cycle is in its life cycle.
    enum CredentialCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A credential cycle as the credential team keeps it.
    final class CredentialCycle {
        var code: String
        var label: String
        var specialty: String
        var ratio: Double
        var currency: String
        var endsAt: Int
        var maximum: Double
        var unit: String
        var floorValue: Double
        var status: CredentialCycleStatus

        init(code: String, label: String, specialty: String, ratio: Double, currency: String, endsAt: Int, maximum: Double, unit: String, floorValue: Double, status: CredentialCycleStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.ratio = ratio
            self.currency = currency
            self.endsAt = endsAt
            self.maximum = maximum
            self.unit = unit
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CredentialCycleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CredentialCycleStatus.resolved || next == CredentialCycleStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == CredentialCycleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedLoad() -> Double {
            return ((maximum + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> CredentialCycle {
            return CredentialCycle(
                code: code,
                label: label,
                specialty: specialty,
                ratio: ratio,
                currency: currency,
                endsAt: endsAt,
                maximum: maximum,
                unit: unit,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a credential cycle in status open.
    static func newCredentialCycle(_ code: String, label: String) -> CredentialCycle {
        return CredentialCycle(
            code: code,
            label: label,
            specialty: "",
            ratio: 0.0,
            currency: "",
            endsAt: 0,
            maximum: 0.0,
            unit: "",
            floorValue: 0.0,
            status: CredentialCycleStatus.`open`
        )
    }
}
