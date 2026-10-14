import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted slot ledger is in its life cycle.
    enum WeightedSlotLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One weighted slot ledger, with what the planners need to act on it.
    final class WeightedSlotLedger {
        var code: String
        var label: String
        var weight: Double
        var budget: Double
        var specialty: String
        var copay: Double
        var name: String
        var status: WeightedSlotLedgerStatus

        init(code: String, label: String, weight: Double, budget: Double, specialty: String, copay: Double, name: String, status: WeightedSlotLedgerStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.budget = budget
            self.specialty = specialty
            self.copay = copay
            self.name = name
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

        func canMoveTo(_ next: WeightedSlotLedgerStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == WeightedSlotLedgerStatus.done || next == WeightedSlotLedgerStatus.failed
            case .done:
                return next == WeightedSlotLedgerStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedSlotLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted slot ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveLoad() -> Double {
            return (copay * budget * 100).rounded() / 100
        }

        func copyValue() -> WeightedSlotLedger {
            return WeightedSlotLedger(
                code: code,
                label: label,
                weight: weight,
                budget: budget,
                specialty: specialty,
                copay: copay,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted slot ledger in status new.
    static func newWeightedSlotLedger(_ code: String, label: String) -> WeightedSlotLedger {
        return WeightedSlotLedger(
            code: code,
            label: label,
            weight: 0.0,
            budget: 0.0,
            specialty: "",
            copay: 0.0,
            name: "",
            status: WeightedSlotLedgerStatus.new
        )
    }
}
