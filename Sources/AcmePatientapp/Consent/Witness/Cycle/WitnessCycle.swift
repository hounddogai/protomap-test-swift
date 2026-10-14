import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness cycle is in its life cycle.
    enum WitnessCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a witness cycle and its current status.
    final class WitnessCycle {
        var code: String
        var name: String
        var diagnosisCode: String
        var ownerID: String
        var procedureCode: String
        var reviewer: String
        var threshold: Double
        var cost: Double
        var floorValue: Double
        var status: WitnessCycleStatus

        init(code: String, name: String, diagnosisCode: String, ownerID: String, procedureCode: String, reviewer: String, threshold: Double, cost: Double, floorValue: Double, status: WitnessCycleStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.ownerID = ownerID
            self.procedureCode = procedureCode
            self.reviewer = reviewer
            self.threshold = threshold
            self.cost = cost
            self.floorValue = floorValue
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

        func canMoveTo(_ next: WitnessCycleStatus) -> Bool {
            switch status {
            case .requested:
                return next == WitnessCycleStatus.granted || next == WitnessCycleStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WitnessCycleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveVolume() -> Double {
            return ((cost - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> WitnessCycle {
            return WitnessCycle(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                ownerID: ownerID,
                procedureCode: procedureCode,
                reviewer: reviewer,
                threshold: threshold,
                cost: cost,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a witness cycle in status requested.
    static func newWitnessCycle(_ code: String, name: String) -> WitnessCycle {
        return WitnessCycle(
            code: code,
            name: name,
            diagnosisCode: "",
            ownerID: "",
            procedureCode: "",
            reviewer: "",
            threshold: 0.0,
            cost: 0.0,
            floorValue: 0.0,
            status: WitnessCycleStatus.requested
        )
    }
}
