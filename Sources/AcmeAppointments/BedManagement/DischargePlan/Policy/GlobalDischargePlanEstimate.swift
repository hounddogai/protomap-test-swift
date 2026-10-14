import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global discharge plan estimate is in its life cycle.
    enum GlobalDischargePlanEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a global discharge plan estimate and its current status.
    final class GlobalDischargePlanEstimate {
        var code: String
        var name: String
        var ownerID: String
        var retries: Int
        var diagnosisCode: String
        var status: GlobalDischargePlanEstimateStatus

        init(code: String, name: String, ownerID: String, retries: Int, diagnosisCode: String, status: GlobalDischargePlanEstimateStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.retries = retries
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: GlobalDischargePlanEstimateStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalDischargePlanEstimateStatus.completed
            case .scheduled:
                switch next {
                case .inProgress:
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
                return next == GlobalDischargePlanEstimateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalDischargePlanEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global discharge plan estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> GlobalDischargePlanEstimate {
            return GlobalDischargePlanEstimate(
                code: code,
                name: name,
                ownerID: ownerID,
                retries: retries,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global discharge plan estimate in status planned.
    static func newGlobalDischargePlanEstimate(_ code: String, name: String) -> GlobalDischargePlanEstimate {
        return GlobalDischargePlanEstimate(
            code: code,
            name: name,
            ownerID: "",
            retries: 0,
            diagnosisCode: "",
            status: GlobalDischargePlanEstimateStatus.planned
        )
    }
}
