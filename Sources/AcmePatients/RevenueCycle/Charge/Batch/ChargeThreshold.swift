import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge threshold is in its life cycle.
    enum ChargeThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a charge threshold and its current status.
    final class ChargeThreshold {
        var code: String
        var name: String
        var timezone: String
        var encounterID: String
        var copay: Double
        var threshold: Double
        var status: ChargeThresholdStatus

        init(code: String, name: String, timezone: String, encounterID: String, copay: Double, threshold: Double, status: ChargeThresholdStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.encounterID = encounterID
            self.copay = copay
            self.threshold = threshold
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

        func canMoveTo(_ next: ChargeThresholdStatus) -> Bool {
            switch status {
            case .planned:
                return next == ChargeThresholdStatus.scheduled || next == ChargeThresholdStatus.cancelled
            case .scheduled:
                switch next {
                case .cancelled:
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
                return next == ChargeThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return (copay * threshold * 100).rounded() / 100
        }

        func copyValue() -> ChargeThreshold {
            return ChargeThreshold(
                code: code,
                name: name,
                timezone: timezone,
                encounterID: encounterID,
                copay: copay,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a charge threshold in status planned.
    static func newChargeThreshold(_ code: String, name: String) -> ChargeThreshold {
        return ChargeThreshold(
            code: code,
            name: name,
            timezone: "",
            encounterID: "",
            copay: 0.0,
            threshold: 0.0,
            status: ChargeThresholdStatus.planned
        )
    }
}
