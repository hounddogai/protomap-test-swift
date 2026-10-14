import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global assessment review is in its life cycle.
    enum GlobalAssessmentReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A global assessment review. Its code is unique within a tenant.
    final class GlobalAssessmentReview {
        var code: String
        var name: String
        var ceiling: Double
        var batchSize: Int
        var currency: String
        var approved: Bool
        var attempts: Int
        var startsAt: Int
        var country: String
        var budget: Double
        var version: Int
        var status: GlobalAssessmentReviewStatus

        init(code: String, name: String, ceiling: Double, batchSize: Int, currency: String, approved: Bool, attempts: Int, startsAt: Int, country: String, budget: Double, version: Int, status: GlobalAssessmentReviewStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.batchSize = batchSize
            self.currency = currency
            self.approved = approved
            self.attempts = attempts
            self.startsAt = startsAt
            self.country = country
            self.budget = budget
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalAssessmentReviewStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == GlobalAssessmentReviewStatus.published || next == GlobalAssessmentReviewStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: GlobalAssessmentReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global assessment review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return ((ceiling - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalAssessmentReview {
            return GlobalAssessmentReview(
                code: code,
                name: name,
                ceiling: ceiling,
                batchSize: batchSize,
                currency: currency,
                approved: approved,
                attempts: attempts,
                startsAt: startsAt,
                country: country,
                budget: budget,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a global assessment review in status created.
    static func newGlobalAssessmentReview(_ code: String, name: String) -> GlobalAssessmentReview {
        return GlobalAssessmentReview(
            code: code,
            name: name,
            ceiling: 0.0,
            batchSize: 0,
            currency: "",
            approved: false,
            attempts: 0,
            startsAt: 0,
            country: "",
            budget: 0.0,
            version: 0,
            status: GlobalAssessmentReviewStatus.created
        )
    }
}
