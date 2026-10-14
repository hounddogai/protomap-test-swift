import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient cleaning estimate is in its life cycle.
    enum LenientCleaningEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One lenient cleaning estimate, with what the planners need to act on it.
    final class LenientCleaningEstimate {
        var code: String
        var name: String
        var acuity: Int
        var budget: Double
        var quantity: Int
        var durationMinutes: Int
        var diagnosisCode: String
        var notes: String
        var ceiling: Double
        var status: LenientCleaningEstimateStatus

        init(code: String, name: String, acuity: Int, budget: Double, quantity: Int, durationMinutes: Int, diagnosisCode: String, notes: String, ceiling: Double, status: LenientCleaningEstimateStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.budget = budget
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
            self.notes = notes
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientCleaningEstimateStatus) -> Bool {
            switch status {
            case .planned:
                return next == LenientCleaningEstimateStatus.completed || next == LenientCleaningEstimateStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LenientCleaningEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient cleaning estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedExposure() -> Double {
            return ((Double(quantity) - budget) * 100).rounded() / 100
        }

        func copyValue() -> LenientCleaningEstimate {
            return LenientCleaningEstimate(
                code: code,
                name: name,
                acuity: acuity,
                budget: budget,
                quantity: quantity,
                durationMinutes: durationMinutes,
                diagnosisCode: diagnosisCode,
                notes: notes,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient cleaning estimate in status planned.
    static func newLenientCleaningEstimate(_ code: String, name: String) -> LenientCleaningEstimate {
        return LenientCleaningEstimate(
            code: code,
            name: name,
            acuity: 0,
            budget: 0.0,
            quantity: 0,
            durationMinutes: 0,
            diagnosisCode: "",
            notes: "",
            ceiling: 0.0,
            status: LenientCleaningEstimateStatus.planned
        )
    }
}
