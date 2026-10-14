import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment score is in its life cycle.
    enum AssessmentScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a assessment score and its current status.
    final class AssessmentScore {
        var code: String
        var title: String
        var rate: Double
        var allergy: String
        var retries: Int
        var ratio: Double
        var reviewer: String
        var createdAt: Int
        var threshold: Double
        var visible: Bool
        var status: AssessmentScoreStatus

        init(code: String, title: String, rate: Double, allergy: String, retries: Int, ratio: Double, reviewer: String, createdAt: Int, threshold: Double, visible: Bool, status: AssessmentScoreStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.allergy = allergy
            self.retries = retries
            self.ratio = ratio
            self.reviewer = reviewer
            self.createdAt = createdAt
            self.threshold = threshold
            self.visible = visible
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

        func canMoveTo(_ next: AssessmentScoreStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AssessmentScoreStatus.rejected
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

        func moveTo(_ next: AssessmentScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netLoad() -> Double {
            return ((ratio + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentScore {
            return AssessmentScore(
                code: code,
                title: title,
                rate: rate,
                allergy: allergy,
                retries: retries,
                ratio: ratio,
                reviewer: reviewer,
                createdAt: createdAt,
                threshold: threshold,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a assessment score in status proposed.
    static func newAssessmentScore(_ code: String, title: String) -> AssessmentScore {
        return AssessmentScore(
            code: code,
            title: title,
            rate: 0.0,
            allergy: "",
            retries: 0,
            ratio: 0.0,
            reviewer: "",
            createdAt: 0,
            threshold: 0.0,
            visible: false,
            status: AssessmentScoreStatus.proposed
        )
    }
}
