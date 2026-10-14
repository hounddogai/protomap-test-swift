import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered modality profile is in its life cycle.
    enum TieredModalityProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered modality profile. Its code is unique within a tenant.
    final class TieredModalityProfile {
        var code: String
        var name: String
        var rate: Double
        var budget: Double
        var label: String
        var status: TieredModalityProfileStatus

        init(code: String, name: String, rate: Double, budget: Double, label: String, status: TieredModalityProfileStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.budget = budget
            self.label = label
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

        func canMoveTo(_ next: TieredModalityProfileStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
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
                return next == TieredModalityProfileStatus.completed
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

        func moveTo(_ next: TieredModalityProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered modality profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func netExposure() -> Double {
            return ((rate + budget) * 100).rounded() / 100
        }

        func copyValue() -> TieredModalityProfile {
            return TieredModalityProfile(
                code: code,
                name: name,
                rate: rate,
                budget: budget,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered modality profile in status planned.
    static func newTieredModalityProfile(_ code: String, name: String) -> TieredModalityProfile {
        return TieredModalityProfile(
            code: code,
            name: name,
            rate: 0.0,
            budget: 0.0,
            label: "",
            status: TieredModalityProfileStatus.planned
        )
    }
}
