import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority checkpoint is in its life cycle.
    enum PriorityCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One priority checkpoint, with what the planners need to act on it.
    final class PriorityCheckpoint {
        var code: String
        var label: String
        var title: String
        var unit: String
        var encounterID: String
        var score: Double
        var currency: String
        var refills: Int
        var specialty: String
        var quantity: Int
        var cost: Double
        var status: PriorityCheckpointStatus

        init(code: String, label: String, title: String, unit: String, encounterID: String, score: Double, currency: String, refills: Int, specialty: String, quantity: Int, cost: Double, status: PriorityCheckpointStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.unit = unit
            self.encounterID = encounterID
            self.score = score
            self.currency = currency
            self.refills = refills
            self.specialty = specialty
            self.quantity = quantity
            self.cost = cost
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

        func canMoveTo(_ next: PriorityCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PriorityCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedTotal() -> Double {
            return ((score - cost) * 100).rounded() / 100
        }

        func copyValue() -> PriorityCheckpoint {
            return PriorityCheckpoint(
                code: code,
                label: label,
                title: title,
                unit: unit,
                encounterID: encounterID,
                score: score,
                currency: currency,
                refills: refills,
                specialty: specialty,
                quantity: quantity,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a priority checkpoint in status planned.
    static func newPriorityCheckpoint(_ code: String, label: String) -> PriorityCheckpoint {
        return PriorityCheckpoint(
            code: code,
            label: label,
            title: "",
            unit: "",
            encounterID: "",
            score: 0.0,
            currency: "",
            refills: 0,
            specialty: "",
            quantity: 0,
            cost: 0.0,
            status: PriorityCheckpointStatus.planned
        )
    }
}
