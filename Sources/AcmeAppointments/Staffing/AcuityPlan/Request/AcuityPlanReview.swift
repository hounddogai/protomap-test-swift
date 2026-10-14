import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan review is in its life cycle.
    enum AcuityPlanReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One acuity plan review, with what the planners need to act on it.
    final class AcuityPlanReview {
        var code: String
        var name: String
        var timezone: String
        var attributes: [String: String]
        var batchSize: Int
        var graceDays: Int
        var attempts: Int
        var score: Double
        var status: AcuityPlanReviewStatus

        init(code: String, name: String, timezone: String, attributes: [String: String], batchSize: Int, graceDays: Int, attempts: Int, score: Double, status: AcuityPlanReviewStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.attributes = attributes
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.attempts = attempts
            self.score = score
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

        func canMoveTo(_ next: AcuityPlanReviewStatus) -> Bool {
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
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AcuityPlanReviewStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func adjustedExposure() -> Double {
            return ((Double(graceDays) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanReview {
            return AcuityPlanReview(
                code: code,
                name: name,
                timezone: timezone,
                attributes: attributes,
                batchSize: batchSize,
                graceDays: graceDays,
                attempts: attempts,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a acuity plan review in status proposed.
    static func newAcuityPlanReview(_ code: String, name: String) -> AcuityPlanReview {
        return AcuityPlanReview(
            code: code,
            name: name,
            timezone: "",
            attributes: [:],
            batchSize: 0,
            graceDays: 0,
            attempts: 0,
            score: 0.0,
            status: AcuityPlanReviewStatus.proposed
        )
    }
}
