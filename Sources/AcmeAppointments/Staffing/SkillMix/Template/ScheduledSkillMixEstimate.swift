import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled skill mix estimate is in its life cycle.
    enum ScheduledSkillMixEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a scheduled skill mix estimate and its current status.
    final class ScheduledSkillMixEstimate {
        var code: String
        var label: String
        var amount: Double
        var description: String
        var specialty: String
        var sequence: Int
        var score: Double
        var country: String
        var copay: Double
        var segment: String
        var endsAt: Int
        var status: ScheduledSkillMixEstimateStatus

        init(code: String, label: String, amount: Double, description: String, specialty: String, sequence: Int, score: Double, country: String, copay: Double, segment: String, endsAt: Int, status: ScheduledSkillMixEstimateStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.description = description
            self.specialty = specialty
            self.sequence = sequence
            self.score = score
            self.country = country
            self.copay = copay
            self.segment = segment
            self.endsAt = endsAt
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

        func canMoveTo(_ next: ScheduledSkillMixEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledSkillMixEstimateStatus.inReview || next == ScheduledSkillMixEstimateStatus.resolved
            case .inReview:
                return next == ScheduledSkillMixEstimateStatus.reopened
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ScheduledSkillMixEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled skill mix estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(sequence) - score) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledSkillMixEstimate {
            return ScheduledSkillMixEstimate(
                code: code,
                label: label,
                amount: amount,
                description: description,
                specialty: specialty,
                sequence: sequence,
                score: score,
                country: country,
                copay: copay,
                segment: segment,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a scheduled skill mix estimate in status open.
    static func newScheduledSkillMixEstimate(_ code: String, label: String) -> ScheduledSkillMixEstimate {
        return ScheduledSkillMixEstimate(
            code: code,
            label: label,
            amount: 0.0,
            description: "",
            specialty: "",
            sequence: 0,
            score: 0.0,
            country: "",
            copay: 0.0,
            segment: "",
            endsAt: 0,
            status: ScheduledSkillMixEstimateStatus.`open`
        )
    }
}
