import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted modality tier is in its life cycle.
    enum WeightedModalityTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One weighted modality tier, with what the planners need to act on it.
    final class WeightedModalityTier {
        var code: String
        var name: String
        var unit: String
        var procedureCode: String
        var copay: Double
        var segment: String
        var status: WeightedModalityTierStatus

        init(code: String, name: String, unit: String, procedureCode: String, copay: Double, segment: String, status: WeightedModalityTierStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.procedureCode = procedureCode
            self.copay = copay
            self.segment = segment
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

        func canMoveTo(_ next: WeightedModalityTierStatus) -> Bool {
            switch status {
            case .planned:
                return next == WeightedModalityTierStatus.completed
            case .scheduled:
                return next == WeightedModalityTierStatus.completed
            case .inProgress:
                return next == WeightedModalityTierStatus.completed || next == WeightedModalityTierStatus.cancelled
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

        func moveTo(_ next: WeightedModalityTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted modality tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> WeightedModalityTier {
            return WeightedModalityTier(
                code: code,
                name: name,
                unit: unit,
                procedureCode: procedureCode,
                copay: copay,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted modality tier in status planned.
    static func newWeightedModalityTier(_ code: String, name: String) -> WeightedModalityTier {
        return WeightedModalityTier(
            code: code,
            name: name,
            unit: "",
            procedureCode: "",
            copay: 0.0,
            segment: "",
            status: WeightedModalityTierStatus.planned
        )
    }
}
