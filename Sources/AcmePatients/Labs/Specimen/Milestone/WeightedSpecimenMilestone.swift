import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted specimen milestone is in its life cycle.
    enum WeightedSpecimenMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A weighted specimen milestone as the specimen team keeps it.
    final class WeightedSpecimenMilestone {
        var code: String
        var name: String
        var score: Double
        var diagnosisCode: String
        var patientRef: String
        var attributes: [String: String]
        var status: WeightedSpecimenMilestoneStatus

        init(code: String, name: String, score: Double, diagnosisCode: String, patientRef: String, attributes: [String: String], status: WeightedSpecimenMilestoneStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.diagnosisCode = diagnosisCode
            self.patientRef = patientRef
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedSpecimenMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: WeightedSpecimenMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted specimen milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted specimen milestone") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> WeightedSpecimenMilestone {
            return WeightedSpecimenMilestone(
                code: code,
                name: name,
                score: score,
                diagnosisCode: diagnosisCode,
                patientRef: patientRef,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted specimen milestone in status idle.
    static func newWeightedSpecimenMilestone(_ code: String, name: String) -> WeightedSpecimenMilestone {
        return WeightedSpecimenMilestone(
            code: code,
            name: name,
            score: 0.0,
            diagnosisCode: "",
            patientRef: "",
            attributes: [:],
            status: WeightedSpecimenMilestoneStatus.idle
        )
    }
}
