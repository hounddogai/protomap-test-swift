import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback goal group is in its life cycle.
    enum FallbackGoalGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One fallback goal group, with what the planners need to act on it.
    final class FallbackGoalGroup {
        var code: String
        var title: String
        var budget: Double
        var endsAt: Int
        var procedureCode: String
        var threshold: Double
        var reviewer: String
        var minimum: Double
        var quantity: Int
        var patientRef: String
        var externalRef: String
        var status: FallbackGoalGroupStatus

        init(code: String, title: String, budget: Double, endsAt: Int, procedureCode: String, threshold: Double, reviewer: String, minimum: Double, quantity: Int, patientRef: String, externalRef: String, status: FallbackGoalGroupStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.endsAt = endsAt
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.reviewer = reviewer
            self.minimum = minimum
            self.quantity = quantity
            self.patientRef = patientRef
            self.externalRef = externalRef
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

        func canMoveTo(_ next: FallbackGoalGroupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackGoalGroupStatus.resolved
            case .inReview:
                return next == FallbackGoalGroupStatus.resolved
            case .resolved:
                return next == FallbackGoalGroupStatus.reopened
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

        func moveTo(_ next: FallbackGoalGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback goal group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback goal group") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((threshold + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackGoalGroup {
            return FallbackGoalGroup(
                code: code,
                title: title,
                budget: budget,
                endsAt: endsAt,
                procedureCode: procedureCode,
                threshold: threshold,
                reviewer: reviewer,
                minimum: minimum,
                quantity: quantity,
                patientRef: patientRef,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback goal group in status open.
    static func newFallbackGoalGroup(_ code: String, title: String) -> FallbackGoalGroup {
        return FallbackGoalGroup(
            code: code,
            title: title,
            budget: 0.0,
            endsAt: 0,
            procedureCode: "",
            threshold: 0.0,
            reviewer: "",
            minimum: 0.0,
            quantity: 0,
            patientRef: "",
            externalRef: "",
            status: FallbackGoalGroupStatus.`open`
        )
    }
}
