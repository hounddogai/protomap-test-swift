import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted specimen slot is in its life cycle.
    enum WeightedSpecimenSlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a weighted specimen slot and its current status.
    final class WeightedSpecimenSlot {
        var code: String
        var name: String
        var externalRef: String
        var acuity: Int
        var segment: String
        var source: String
        var minimum: Double
        var clinicianID: String
        var amount: Double
        var quantity: Int
        var status: WeightedSpecimenSlotStatus

        init(code: String, name: String, externalRef: String, acuity: Int, segment: String, source: String, minimum: Double, clinicianID: String, amount: Double, quantity: Int, status: WeightedSpecimenSlotStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.acuity = acuity
            self.segment = segment
            self.source = source
            self.minimum = minimum
            self.clinicianID = clinicianID
            self.amount = amount
            self.quantity = quantity
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

        func canMoveTo(_ next: WeightedSpecimenSlotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: WeightedSpecimenSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted specimen slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netTotal() -> Double {
            return (amount * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> WeightedSpecimenSlot {
            return WeightedSpecimenSlot(
                code: code,
                name: name,
                externalRef: externalRef,
                acuity: acuity,
                segment: segment,
                source: source,
                minimum: minimum,
                clinicianID: clinicianID,
                amount: amount,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a weighted specimen slot in status idle.
    static func newWeightedSpecimenSlot(_ code: String, name: String) -> WeightedSpecimenSlot {
        return WeightedSpecimenSlot(
            code: code,
            name: name,
            externalRef: "",
            acuity: 0,
            segment: "",
            source: "",
            minimum: 0.0,
            clinicianID: "",
            amount: 0.0,
            quantity: 0,
            status: WeightedSpecimenSlotStatus.idle
        )
    }
}
