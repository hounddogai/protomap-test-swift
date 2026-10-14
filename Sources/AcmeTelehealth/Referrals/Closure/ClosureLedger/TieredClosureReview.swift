import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered closure review is in its life cycle.
    enum TieredClosureReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A tiered closure review. Its code is unique within a tenant.
    final class TieredClosureReview {
        var code: String
        var name: String
        var revision: Int
        var active: Bool
        var expiresAt: Int
        var createdAt: Int
        var status: TieredClosureReviewStatus

        init(code: String, name: String, revision: Int, active: Bool, expiresAt: Int, createdAt: Int, status: TieredClosureReviewStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.active = active
            self.expiresAt = expiresAt
            self.createdAt = createdAt
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

        func canMoveTo(_ next: TieredClosureReviewStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == TieredClosureReviewStatus.resolved
            case .resolved:
                return next == TieredClosureReviewStatus.reopened || next == TieredClosureReviewStatus.archived
            case .reopened:
                return next == TieredClosureReviewStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredClosureReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered closure review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedVolume() -> Double {
            return ((Double(expiresAt) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredClosureReview {
            return TieredClosureReview(
                code: code,
                name: name,
                revision: revision,
                active: active,
                expiresAt: expiresAt,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered closure review in status open.
    static func newTieredClosureReview(_ code: String, name: String) -> TieredClosureReview {
        return TieredClosureReview(
            code: code,
            name: name,
            revision: 0,
            active: false,
            expiresAt: 0,
            createdAt: 0,
            status: TieredClosureReviewStatus.`open`
        )
    }
}
