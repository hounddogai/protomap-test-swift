import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual closure score is in its life cycle.
    enum ManualClosureScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual closure score. Its code is unique within a tenant.
    final class ManualClosureScore {
        var code: String
        var label: String
        var threshold: Double
        var region: String
        var minimum: Double
        var title: String
        var encounterID: String
        var status: ManualClosureScoreStatus

        init(code: String, label: String, threshold: Double, region: String, minimum: Double, title: String, encounterID: String, status: ManualClosureScoreStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.region = region
            self.minimum = minimum
            self.title = title
            self.encounterID = encounterID
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

        func canMoveTo(_ next: ManualClosureScoreStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ManualClosureScoreStatus.cancelled
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

        func moveTo(_ next: ManualClosureScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual closure score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual closure score") \(code)"
        }

        func netExposure() -> Double {
            return (minimum * threshold * 100).rounded() / 100
        }

        func copyValue() -> ManualClosureScore {
            return ManualClosureScore(
                code: code,
                label: label,
                threshold: threshold,
                region: region,
                minimum: minimum,
                title: title,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual closure score in status planned.
    static func newManualClosureScore(_ code: String, label: String) -> ManualClosureScore {
        return ManualClosureScore(
            code: code,
            label: label,
            threshold: 0.0,
            region: "",
            minimum: 0.0,
            title: "",
            encounterID: "",
            status: ManualClosureScoreStatus.planned
        )
    }
}
