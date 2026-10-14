import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal accession adjustment is in its life cycle.
    enum SeasonalAccessionAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a seasonal accession adjustment and its current status.
    final class SeasonalAccessionAdjustment {
        var code: String
        var name: String
        var minimum: Double
        var visitMinutes: Int
        var floorValue: Double
        var status: SeasonalAccessionAdjustmentStatus

        init(code: String, name: String, minimum: Double, visitMinutes: Int, floorValue: Double, status: SeasonalAccessionAdjustmentStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.visitMinutes = visitMinutes
            self.floorValue = floorValue
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

        func canMoveTo(_ next: SeasonalAccessionAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalAccessionAdjustmentStatus.inProgress || next == SeasonalAccessionAdjustmentStatus.completed
            case .scheduled:
                return next == SeasonalAccessionAdjustmentStatus.inProgress || next == SeasonalAccessionAdjustmentStatus.cancelled
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

        func moveTo(_ next: SeasonalAccessionAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal accession adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return ((floorValue - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalAccessionAdjustment {
            return SeasonalAccessionAdjustment(
                code: code,
                name: name,
                minimum: minimum,
                visitMinutes: visitMinutes,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal accession adjustment in status planned.
    static func newSeasonalAccessionAdjustment(_ code: String, name: String) -> SeasonalAccessionAdjustment {
        return SeasonalAccessionAdjustment(
            code: code,
            name: name,
            minimum: 0.0,
            visitMinutes: 0,
            floorValue: 0.0,
            status: SeasonalAccessionAdjustmentStatus.planned
        )
    }
}
