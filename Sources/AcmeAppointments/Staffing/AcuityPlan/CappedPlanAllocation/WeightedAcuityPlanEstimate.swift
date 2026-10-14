import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted acuity plan estimate is in its life cycle.
    enum WeightedAcuityPlanEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One weighted acuity plan estimate, with what the planners need to act on it.
    final class WeightedAcuityPlanEstimate {
        var code: String
        var name: String
        var retries: Int
        var reviewer: String
        var endsAt: Int
        var revision: Int
        var floorValue: Double
        var threshold: Double
        var facility: String
        var visitMinutes: Int
        var status: WeightedAcuityPlanEstimateStatus

        init(code: String, name: String, retries: Int, reviewer: String, endsAt: Int, revision: Int, floorValue: Double, threshold: Double, facility: String, visitMinutes: Int, status: WeightedAcuityPlanEstimateStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.revision = revision
            self.floorValue = floorValue
            self.threshold = threshold
            self.facility = facility
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedAcuityPlanEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == WeightedAcuityPlanEstimateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedAcuityPlanEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted acuity plan estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedLoad() -> Double {
            return ((floorValue + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedAcuityPlanEstimate {
            return WeightedAcuityPlanEstimate(
                code: code,
                name: name,
                retries: retries,
                reviewer: reviewer,
                endsAt: endsAt,
                revision: revision,
                floorValue: floorValue,
                threshold: threshold,
                facility: facility,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted acuity plan estimate in status proposed.
    static func newWeightedAcuityPlanEstimate(_ code: String, name: String) -> WeightedAcuityPlanEstimate {
        return WeightedAcuityPlanEstimate(
            code: code,
            name: name,
            retries: 0,
            reviewer: "",
            endsAt: 0,
            revision: 0,
            floorValue: 0.0,
            threshold: 0.0,
            facility: "",
            visitMinutes: 0,
            status: WeightedAcuityPlanEstimateStatus.proposed
        )
    }
}
