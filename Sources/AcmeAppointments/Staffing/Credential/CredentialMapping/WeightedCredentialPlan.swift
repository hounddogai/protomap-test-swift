import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted credential plan is in its life cycle.
    enum WeightedCredentialPlanStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a weighted credential plan and its current status.
    final class WeightedCredentialPlan {
        var code: String
        var name: String
        var startsAt: Int
        var retries: Int
        var region: String
        var minimum: Double
        var status: WeightedCredentialPlanStatus

        init(code: String, name: String, startsAt: Int, retries: Int, region: String, minimum: Double, status: WeightedCredentialPlanStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.retries = retries
            self.region = region
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedCredentialPlanStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedCredentialPlanStatus.validated || next == WeightedCredentialPlanStatus.published
            case .validated:
                return next == WeightedCredentialPlanStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WeightedCredentialPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted credential plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return (Double(startsAt) * minimum * 100).rounded() / 100
        }

        func copyValue() -> WeightedCredentialPlan {
            return WeightedCredentialPlan(
                code: code,
                name: name,
                startsAt: startsAt,
                retries: retries,
                region: region,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted credential plan in status created.
    static func newWeightedCredentialPlan(_ code: String, name: String) -> WeightedCredentialPlan {
        return WeightedCredentialPlan(
            code: code,
            name: name,
            startsAt: 0,
            retries: 0,
            region: "",
            minimum: 0.0,
            status: WeightedCredentialPlanStatus.created
        )
    }
}
