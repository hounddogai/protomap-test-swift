import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness claim is in its life cycle.
    enum WitnessClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A witness claim. Its code is unique within a tenant.
    final class WitnessClaim {
        var code: String
        var label: String
        var rate: Double
        var capacity: Int
        var notes: String
        var name: String
        var cost: Double
        var facility: String
        var status: WitnessClaimStatus

        init(code: String, label: String, rate: Double, capacity: Int, notes: String, name: String, cost: Double, facility: String, status: WitnessClaimStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.capacity = capacity
            self.notes = notes
            self.name = name
            self.cost = cost
            self.facility = facility
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

        func canMoveTo(_ next: WitnessClaimStatus) -> Bool {
            switch status {
            case .created:
                return next == WitnessClaimStatus.validated
            case .validated:
                switch next {
                case .published:
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

        func moveTo(_ next: WitnessClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveValue() -> Double {
            return ((Double(capacity) + rate) * 100).rounded() / 100
        }

        func copyValue() -> WitnessClaim {
            return WitnessClaim(
                code: code,
                label: label,
                rate: rate,
                capacity: capacity,
                notes: notes,
                name: name,
                cost: cost,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a witness claim in status created.
    static func newWitnessClaim(_ code: String, label: String) -> WitnessClaim {
        return WitnessClaim(
            code: code,
            label: label,
            rate: 0.0,
            capacity: 0,
            notes: "",
            name: "",
            cost: 0.0,
            facility: "",
            status: WitnessClaimStatus.created
        )
    }
}
