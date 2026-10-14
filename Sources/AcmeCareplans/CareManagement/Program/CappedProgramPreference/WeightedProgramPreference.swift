import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted program preference is in its life cycle.
    enum WeightedProgramPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a weighted program preference and its current status.
    final class WeightedProgramPreference {
        var code: String
        var label: String
        var ratio: Double
        var category: String
        var rate: Double
        var status: WeightedProgramPreferenceStatus

        init(code: String, label: String, ratio: Double, category: String, rate: Double, status: WeightedProgramPreferenceStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.category = category
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedProgramPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == WeightedProgramPreferenceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedProgramPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted program preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedVolume() -> Double {
            return ((ratio - rate) * 100).rounded() / 100
        }

        func copyValue() -> WeightedProgramPreference {
            return WeightedProgramPreference(
                code: code,
                label: label,
                ratio: ratio,
                category: category,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a weighted program preference in status idle.
    static func newWeightedProgramPreference(_ code: String, label: String) -> WeightedProgramPreference {
        return WeightedProgramPreference(
            code: code,
            label: label,
            ratio: 0.0,
            category: "",
            rate: 0.0,
            status: WeightedProgramPreferenceStatus.idle
        )
    }
}
