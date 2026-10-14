import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered rounding adjustment is in its life cycle.
    enum TieredRoundingAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One tiered rounding adjustment, with what the planners need to act on it.
    final class TieredRoundingAdjustment {
        var code: String
        var title: String
        var threshold: Double
        var specialty: String
        var ward: String
        var budget: Double
        var name: String
        var status: TieredRoundingAdjustmentStatus

        init(code: String, title: String, threshold: Double, specialty: String, ward: String, budget: Double, name: String, status: TieredRoundingAdjustmentStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.specialty = specialty
            self.ward = ward
            self.budget = budget
            self.name = name
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

        func canMoveTo(_ next: TieredRoundingAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredRoundingAdjustmentStatus.scheduled || next == TieredRoundingAdjustmentStatus.cancelled
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
                case .completed, .cancelled:
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

        func moveTo(_ next: TieredRoundingAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered rounding adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered rounding adjustment") \(code)"
        }

        func netLoad() -> Double {
            return ((threshold + budget) * 100).rounded() / 100
        }

        func copyValue() -> TieredRoundingAdjustment {
            return TieredRoundingAdjustment(
                code: code,
                title: title,
                threshold: threshold,
                specialty: specialty,
                ward: ward,
                budget: budget,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a tiered rounding adjustment in status planned.
    static func newTieredRoundingAdjustment(_ code: String, title: String) -> TieredRoundingAdjustment {
        return TieredRoundingAdjustment(
            code: code,
            title: title,
            threshold: 0.0,
            specialty: "",
            ward: "",
            budget: 0.0,
            name: "",
            status: TieredRoundingAdjustmentStatus.planned
        )
    }
}
