import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal override is in its life cycle.
    enum GoalOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A goal override as the goal team keeps it.
    final class GoalOverride {
        var code: String
        var name: String
        var sequence: Int
        var visible: Bool
        var threshold: Double
        var weight: Double
        var diagnosisCode: String
        var status: GoalOverrideStatus

        init(code: String, name: String, sequence: Int, visible: Bool, threshold: Double, weight: Double, diagnosisCode: String, status: GoalOverrideStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.visible = visible
            self.threshold = threshold
            self.weight = weight
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: GoalOverrideStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
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

        func moveTo(_ next: GoalOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return ((weight + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> GoalOverride {
            return GoalOverride(
                code: code,
                name: name,
                sequence: sequence,
                visible: visible,
                threshold: threshold,
                weight: weight,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a goal override in status requested.
    static func newGoalOverride(_ code: String, name: String) -> GoalOverride {
        return GoalOverride(
            code: code,
            name: name,
            sequence: 0,
            visible: false,
            threshold: 0.0,
            weight: 0.0,
            diagnosisCode: "",
            status: GoalOverrideStatus.requested
        )
    }
}
