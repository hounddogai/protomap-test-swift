import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched discharge plan draft is in its life cycle.
    enum BatchedDischargePlanDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched discharge plan draft. Its code is unique within a tenant.
    final class BatchedDischargePlanDraft {
        var code: String
        var name: String
        var phone: String
        var rate: Double
        var updatedAt: Int
        var discount: Double
        var status: BatchedDischargePlanDraftStatus

        init(code: String, name: String, phone: String, rate: Double, updatedAt: Int, discount: Double, status: BatchedDischargePlanDraftStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.rate = rate
            self.updatedAt = updatedAt
            self.discount = discount
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

        func canMoveTo(_ next: BatchedDischargePlanDraftStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == BatchedDischargePlanDraftStatus.reopened || next == BatchedDischargePlanDraftStatus.archived
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

        func moveTo(_ next: BatchedDischargePlanDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched discharge plan draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedVolume() -> Double {
            return ((rate - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDischargePlanDraft {
            return BatchedDischargePlanDraft(
                code: code,
                name: name,
                phone: phone,
                rate: rate,
                updatedAt: updatedAt,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched discharge plan draft in status open.
    static func newBatchedDischargePlanDraft(_ code: String, name: String) -> BatchedDischargePlanDraft {
        return BatchedDischargePlanDraft(
            code: code,
            name: name,
            phone: "",
            rate: 0.0,
            updatedAt: 0,
            discount: 0.0,
            status: BatchedDischargePlanDraftStatus.`open`
        )
    }
}
