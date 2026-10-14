import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal baseline is in its life cycle.
    enum GoalBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a goal baseline and its current status.
    final class GoalBaseline {
        var code: String
        var name: String
        var diagnosisCode: String
        var currency: String
        var maximum: Double
        var payer: String
        var retries: Int
        var capacity: Int
        var version: Int
        var segment: String
        var revision: Int
        var status: GoalBaselineStatus

        init(code: String, name: String, diagnosisCode: String, currency: String, maximum: Double, payer: String, retries: Int, capacity: Int, version: Int, segment: String, revision: Int, status: GoalBaselineStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.currency = currency
            self.maximum = maximum
            self.payer = payer
            self.retries = retries
            self.capacity = capacity
            self.version = version
            self.segment = segment
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GoalBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == GoalBaselineStatus.resolved || next == GoalBaselineStatus.reopened
            case .resolved:
                return next == GoalBaselineStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: GoalBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedTotal() -> Double {
            return (Double(retries) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> GoalBaseline {
            return GoalBaseline(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                currency: currency,
                maximum: maximum,
                payer: payer,
                retries: retries,
                capacity: capacity,
                version: version,
                segment: segment,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a goal baseline in status open.
    static func newGoalBaseline(_ code: String, name: String) -> GoalBaseline {
        return GoalBaseline(
            code: code,
            name: name,
            diagnosisCode: "",
            currency: "",
            maximum: 0.0,
            payer: "",
            retries: 0,
            capacity: 0,
            version: 0,
            segment: "",
            revision: 0,
            status: GoalBaselineStatus.`open`
        )
    }
}
