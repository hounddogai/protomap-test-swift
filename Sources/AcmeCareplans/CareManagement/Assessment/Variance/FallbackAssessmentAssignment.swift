import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback assessment assignment is in its life cycle.
    enum FallbackAssessmentAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback assessment assignment. Its code is unique within a tenant.
    final class FallbackAssessmentAssignment {
        var code: String
        var title: String
        var ratio: Double
        var score: Double
        var createdAt: Int
        var weight: Double
        var sequence: Int
        var status: FallbackAssessmentAssignmentStatus

        init(code: String, title: String, ratio: Double, score: Double, createdAt: Int, weight: Double, sequence: Int, status: FallbackAssessmentAssignmentStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.score = score
            self.createdAt = createdAt
            self.weight = weight
            self.sequence = sequence
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

        func canMoveTo(_ next: FallbackAssessmentAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackAssessmentAssignmentStatus.inReview || next == FallbackAssessmentAssignmentStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FallbackAssessmentAssignmentStatus.archived
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

        func moveTo(_ next: FallbackAssessmentAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback assessment assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return ((Double(sequence) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackAssessmentAssignment {
            return FallbackAssessmentAssignment(
                code: code,
                title: title,
                ratio: ratio,
                score: score,
                createdAt: createdAt,
                weight: weight,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback assessment assignment in status open.
    static func newFallbackAssessmentAssignment(_ code: String, title: String) -> FallbackAssessmentAssignment {
        return FallbackAssessmentAssignment(
            code: code,
            title: title,
            ratio: 0.0,
            score: 0.0,
            createdAt: 0,
            weight: 0.0,
            sequence: 0,
            status: FallbackAssessmentAssignmentStatus.`open`
        )
    }
}
