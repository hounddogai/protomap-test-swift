import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal handoff threshold is in its life cycle.
    enum SeasonalHandoffThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A seasonal handoff threshold. Its code is unique within a tenant.
    final class SeasonalHandoffThreshold {
        var code: String
        var label: String
        var segment: String
        var ratio: Double
        var retries: Int
        var weight: Double
        var status: SeasonalHandoffThresholdStatus

        init(code: String, label: String, segment: String, ratio: Double, retries: Int, weight: Double, status: SeasonalHandoffThresholdStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.ratio = ratio
            self.retries = retries
            self.weight = weight
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

        func canMoveTo(_ next: SeasonalHandoffThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == SeasonalHandoffThresholdStatus.completed
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

        func moveTo(_ next: SeasonalHandoffThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal handoff threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return ((Double(retries) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalHandoffThreshold {
            return SeasonalHandoffThreshold(
                code: code,
                label: label,
                segment: segment,
                ratio: ratio,
                retries: retries,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a seasonal handoff threshold in status planned.
    static func newSeasonalHandoffThreshold(_ code: String, label: String) -> SeasonalHandoffThreshold {
        return SeasonalHandoffThreshold(
            code: code,
            label: label,
            segment: "",
            ratio: 0.0,
            retries: 0,
            weight: 0.0,
            status: SeasonalHandoffThresholdStatus.planned
        )
    }
}
