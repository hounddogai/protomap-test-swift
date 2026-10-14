import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial cycle is in its life cycle.
    enum DenialCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A denial cycle as the denial team keeps it.
    final class DenialCycle {
        var code: String
        var name: String
        var budget: Double
        var reviewer: String
        var ceiling: Double
        var sequence: Int
        var ward: String
        var amount: Double
        var diagnosisCode: String
        var status: DenialCycleStatus

        init(code: String, name: String, budget: Double, reviewer: String, ceiling: Double, sequence: Int, ward: String, amount: Double, diagnosisCode: String, status: DenialCycleStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.reviewer = reviewer
            self.ceiling = ceiling
            self.sequence = sequence
            self.ward = ward
            self.amount = amount
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: DenialCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == DenialCycleStatus.published
            case .validated:
                return next == DenialCycleStatus.published
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

        func moveTo(_ next: DenialCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("denial cycle") \(code)"
        }

        func projectedVolume() -> Double {
            return (budget * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> DenialCycle {
            return DenialCycle(
                code: code,
                name: name,
                budget: budget,
                reviewer: reviewer,
                ceiling: ceiling,
                sequence: sequence,
                ward: ward,
                amount: amount,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a denial cycle in status created.
    static func newDenialCycle(_ code: String, name: String) -> DenialCycle {
        return DenialCycle(
            code: code,
            name: name,
            budget: 0.0,
            reviewer: "",
            ceiling: 0.0,
            sequence: 0,
            ward: "",
            amount: 0.0,
            diagnosisCode: "",
            status: DenialCycleStatus.created
        )
    }
}
