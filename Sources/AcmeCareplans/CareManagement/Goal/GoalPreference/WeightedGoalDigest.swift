import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted goal digest is in its life cycle.
    enum WeightedGoalDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a weighted goal digest and its current status.
    final class WeightedGoalDigest {
        var code: String
        var name: String
        var quantity: Int
        var maximum: Double
        var source: String
        var reviewer: String
        var floorValue: Double
        var procedureCode: String
        var status: WeightedGoalDigestStatus

        init(code: String, name: String, quantity: Int, maximum: Double, source: String, reviewer: String, floorValue: Double, procedureCode: String, status: WeightedGoalDigestStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.maximum = maximum
            self.source = source
            self.reviewer = reviewer
            self.floorValue = floorValue
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: WeightedGoalDigestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == WeightedGoalDigestStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: WeightedGoalDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted goal digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return (floorValue * maximum * 100).rounded() / 100
        }

        func copyValue() -> WeightedGoalDigest {
            return WeightedGoalDigest(
                code: code,
                name: name,
                quantity: quantity,
                maximum: maximum,
                source: source,
                reviewer: reviewer,
                floorValue: floorValue,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a weighted goal digest in status proposed.
    static func newWeightedGoalDigest(_ code: String, name: String) -> WeightedGoalDigest {
        return WeightedGoalDigest(
            code: code,
            name: name,
            quantity: 0,
            maximum: 0.0,
            source: "",
            reviewer: "",
            floorValue: 0.0,
            procedureCode: "",
            status: WeightedGoalDigestStatus.proposed
        )
    }
}
