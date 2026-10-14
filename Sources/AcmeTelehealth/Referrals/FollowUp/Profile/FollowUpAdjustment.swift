import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up adjustment is in its life cycle.
    enum FollowUpAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A follow up adjustment. Its code is unique within a tenant.
    final class FollowUpAdjustment {
        var code: String
        var name: String
        var approved: Bool
        var quantity: Int
        var threshold: Double
        var ownerID: String
        var payer: String
        var score: Double
        var limit: Int
        var version: Int
        var status: FollowUpAdjustmentStatus

        init(code: String, name: String, approved: Bool, quantity: Int, threshold: Double, ownerID: String, payer: String, score: Double, limit: Int, version: Int, status: FollowUpAdjustmentStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.quantity = quantity
            self.threshold = threshold
            self.ownerID = ownerID
            self.payer = payer
            self.score = score
            self.limit = limit
            self.version = version
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

        func canMoveTo(_ next: FollowUpAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == FollowUpAdjustmentStatus.active || next == FollowUpAdjustmentStatus.suspended
            case .pending:
                return next == FollowUpAdjustmentStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FollowUpAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveTotal() -> Double {
            return (Double(limit) * score * 100).rounded() / 100
        }

        func copyValue() -> FollowUpAdjustment {
            return FollowUpAdjustment(
                code: code,
                name: name,
                approved: approved,
                quantity: quantity,
                threshold: threshold,
                ownerID: ownerID,
                payer: payer,
                score: score,
                limit: limit,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a follow up adjustment in status draft.
    static func newFollowUpAdjustment(_ code: String, name: String) -> FollowUpAdjustment {
        return FollowUpAdjustment(
            code: code,
            name: name,
            approved: false,
            quantity: 0,
            threshold: 0.0,
            ownerID: "",
            payer: "",
            score: 0.0,
            limit: 0,
            version: 0,
            status: FollowUpAdjustmentStatus.draft
        )
    }
}
