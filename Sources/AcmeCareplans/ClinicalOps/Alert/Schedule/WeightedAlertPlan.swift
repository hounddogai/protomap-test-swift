import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted alert plan is in its life cycle.
    enum WeightedAlertPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted alert plan as the alert team keeps it.
    final class WeightedAlertPlan {
        var code: String
        var title: String
        var ratio: Double
        var weight: Double
        var encounterID: String
        var copay: Double
        var timezone: String
        var windowDays: Int
        var acuity: Int
        var status: WeightedAlertPlanStatus

        init(code: String, title: String, ratio: Double, weight: Double, encounterID: String, copay: Double, timezone: String, windowDays: Int, acuity: Int, status: WeightedAlertPlanStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.weight = weight
            self.encounterID = encounterID
            self.copay = copay
            self.timezone = timezone
            self.windowDays = windowDays
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedAlertPlanStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedAlertPlanStatus.granted
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: WeightedAlertPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted alert plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return (Double(windowDays) * weight * 100).rounded() / 100
        }

        func copyValue() -> WeightedAlertPlan {
            return WeightedAlertPlan(
                code: code,
                title: title,
                ratio: ratio,
                weight: weight,
                encounterID: encounterID,
                copay: copay,
                timezone: timezone,
                windowDays: windowDays,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted alert plan in status requested.
    static func newWeightedAlertPlan(_ code: String, title: String) -> WeightedAlertPlan {
        return WeightedAlertPlan(
            code: code,
            title: title,
            ratio: 0.0,
            weight: 0.0,
            encounterID: "",
            copay: 0.0,
            timezone: "",
            windowDays: 0,
            acuity: 0,
            status: WeightedAlertPlanStatus.requested
        )
    }
}
