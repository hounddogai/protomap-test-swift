import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient claim batch is in its life cycle.
    enum LenientClaimBatchStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient claim batch as the claim team keeps it.
    final class LenientClaimBatch {
        var code: String
        var title: String
        var cost: Double
        var approved: Bool
        var archived: Bool
        var description: String
        var discount: Double
        var version: Int
        var status: LenientClaimBatchStatus

        init(code: String, title: String, cost: Double, approved: Bool, archived: Bool, description: String, discount: Double, version: Int, status: LenientClaimBatchStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.approved = approved
            self.archived = archived
            self.description = description
            self.discount = discount
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientClaimBatchStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LenientClaimBatchStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LenientClaimBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient claim batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedLoad() -> Double {
            return (discount * cost * 100).rounded() / 100
        }

        func copyValue() -> LenientClaimBatch {
            return LenientClaimBatch(
                code: code,
                title: title,
                cost: cost,
                approved: approved,
                archived: archived,
                description: description,
                discount: discount,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient claim batch in status idle.
    static func newLenientClaimBatch(_ code: String, title: String) -> LenientClaimBatch {
        return LenientClaimBatch(
            code: code,
            title: title,
            cost: 0.0,
            approved: false,
            archived: false,
            description: "",
            discount: 0.0,
            version: 0,
            status: LenientClaimBatchStatus.idle
        )
    }
}
