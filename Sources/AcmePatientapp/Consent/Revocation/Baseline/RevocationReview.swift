import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation review is in its life cycle.
    enum RevocationReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One revocation review, with what the planners need to act on it.
    final class RevocationReview {
        var code: String
        var title: String
        var version: Int
        var budget: Double
        var diagnosisCode: String
        var createdAt: Int
        var ceiling: Double
        var status: RevocationReviewStatus

        init(code: String, title: String, version: Int, budget: Double, diagnosisCode: String, createdAt: Int, ceiling: Double, status: RevocationReviewStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.budget = budget
            self.diagnosisCode = diagnosisCode
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationReviewStatus) -> Bool {
            switch status {
            case .draft:
                return next == RevocationReviewStatus.active || next == RevocationReviewStatus.closed
            case .pending:
                return next == RevocationReviewStatus.active
            case .active:
                return next == RevocationReviewStatus.suspended || next == RevocationReviewStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RevocationReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedExposure() -> Double {
            return ((ceiling - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationReview {
            return RevocationReview(
                code: code,
                title: title,
                version: version,
                budget: budget,
                diagnosisCode: diagnosisCode,
                createdAt: createdAt,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a revocation review in status draft.
    static func newRevocationReview(_ code: String, title: String) -> RevocationReview {
        return RevocationReview(
            code: code,
            title: title,
            version: 0,
            budget: 0.0,
            diagnosisCode: "",
            createdAt: 0,
            ceiling: 0.0,
            status: RevocationReviewStatus.draft
        )
    }
}
