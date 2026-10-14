import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted charge threshold is in its life cycle.
    enum WeightedChargeThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a weighted charge threshold and its current status.
    final class WeightedChargeThreshold {
        var code: String
        var name: String
        var version: Int
        var refills: Int
        var notes: String
        var status: WeightedChargeThresholdStatus

        init(code: String, name: String, version: Int, refills: Int, notes: String, status: WeightedChargeThresholdStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.refills = refills
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedChargeThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == WeightedChargeThresholdStatus.resolved || next == WeightedChargeThresholdStatus.archived
            case .resolved:
                return next == WeightedChargeThresholdStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: WeightedChargeThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted charge threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return (Double(version) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> WeightedChargeThreshold {
            return WeightedChargeThreshold(
                code: code,
                name: name,
                version: version,
                refills: refills,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted charge threshold in status open.
    static func newWeightedChargeThreshold(_ code: String, name: String) -> WeightedChargeThreshold {
        return WeightedChargeThreshold(
            code: code,
            name: name,
            version: 0,
            refills: 0,
            notes: "",
            status: WeightedChargeThresholdStatus.`open`
        )
    }
}
