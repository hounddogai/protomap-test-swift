import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial review is in its life cycle.
    enum DenialReviewStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A denial review as the denial team keeps it.
    final class DenialReview {
        var code: String
        var name: String
        var archived: Bool
        var durationMinutes: Int
        var currency: String
        var expiresAt: Int
        var weight: Double
        var batchSize: Int
        var status: DenialReviewStatus

        init(code: String, name: String, archived: Bool, durationMinutes: Int, currency: String, expiresAt: Int, weight: Double, batchSize: Int, status: DenialReviewStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.currency = currency
            self.expiresAt = expiresAt
            self.weight = weight
            self.batchSize = batchSize
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

        func canMoveTo(_ next: DenialReviewStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DenialReviewStatus.rejected || next == DenialReviewStatus.withdrawn
            case .rejected:
                return next == DenialReviewStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return (Double(durationMinutes) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> DenialReview {
            return DenialReview(
                code: code,
                name: name,
                archived: archived,
                durationMinutes: durationMinutes,
                currency: currency,
                expiresAt: expiresAt,
                weight: weight,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a denial review in status proposed.
    static func newDenialReview(_ code: String, name: String) -> DenialReview {
        return DenialReview(
            code: code,
            name: name,
            archived: false,
            durationMinutes: 0,
            currency: "",
            expiresAt: 0,
            weight: 0.0,
            batchSize: 0,
            status: DenialReviewStatus.proposed
        )
    }
}
