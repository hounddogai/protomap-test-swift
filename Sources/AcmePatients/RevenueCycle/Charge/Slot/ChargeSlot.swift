import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge slot is in its life cycle.
    enum ChargeSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One charge slot, with what the planners need to act on it.
    final class ChargeSlot {
        var code: String
        var label: String
        var visitMinutes: Int
        var maximum: Double
        var budget: Double
        var specialty: String
        var rate: Double
        var externalRef: String
        var copay: Double
        var reviewer: String
        var allergy: String
        var status: ChargeSlotStatus

        init(code: String, label: String, visitMinutes: Int, maximum: Double, budget: Double, specialty: String, rate: Double, externalRef: String, copay: Double, reviewer: String, allergy: String, status: ChargeSlotStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.maximum = maximum
            self.budget = budget
            self.specialty = specialty
            self.rate = rate
            self.externalRef = externalRef
            self.copay = copay
            self.reviewer = reviewer
            self.allergy = allergy
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

        func canMoveTo(_ next: ChargeSlotStatus) -> Bool {
            switch status {
            case .created:
                return next == ChargeSlotStatus.validated || next == ChargeSlotStatus.retired
            case .validated:
                return next == ChargeSlotStatus.published
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

        func moveTo(_ next: ChargeSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netLoad() -> Double {
            return ((copay - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeSlot {
            return ChargeSlot(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                maximum: maximum,
                budget: budget,
                specialty: specialty,
                rate: rate,
                externalRef: externalRef,
                copay: copay,
                reviewer: reviewer,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a charge slot in status created.
    static func newChargeSlot(_ code: String, label: String) -> ChargeSlot {
        return ChargeSlot(
            code: code,
            label: label,
            visitMinutes: 0,
            maximum: 0.0,
            budget: 0.0,
            specialty: "",
            rate: 0.0,
            externalRef: "",
            copay: 0.0,
            reviewer: "",
            allergy: "",
            status: ChargeSlotStatus.created
        )
    }
}
