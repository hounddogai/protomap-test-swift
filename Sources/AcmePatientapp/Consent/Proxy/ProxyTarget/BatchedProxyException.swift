import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched proxy exception is in its life cycle.
    enum BatchedProxyExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a batched proxy exception and its current status.
    final class BatchedProxyException {
        var code: String
        var title: String
        var category: String
        var tags: [String]
        var expiresAt: Int
        var currency: String
        var maximum: Double
        var ratio: Double
        var approved: Bool
        var ceiling: Double
        var copay: Double
        var status: BatchedProxyExceptionStatus

        init(code: String, title: String, category: String, tags: [String], expiresAt: Int, currency: String, maximum: Double, ratio: Double, approved: Bool, ceiling: Double, copay: Double, status: BatchedProxyExceptionStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.tags = tags
            self.expiresAt = expiresAt
            self.currency = currency
            self.maximum = maximum
            self.ratio = ratio
            self.approved = approved
            self.ceiling = ceiling
            self.copay = copay
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

        func canMoveTo(_ next: BatchedProxyExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedProxyExceptionStatus.approved || next == BatchedProxyExceptionStatus.rejected
            case .approved:
                return next == BatchedProxyExceptionStatus.rejected || next == BatchedProxyExceptionStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: BatchedProxyExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched proxy exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return (ratio * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> BatchedProxyException {
            return BatchedProxyException(
                code: code,
                title: title,
                category: category,
                tags: tags,
                expiresAt: expiresAt,
                currency: currency,
                maximum: maximum,
                ratio: ratio,
                approved: approved,
                ceiling: ceiling,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched proxy exception in status proposed.
    static func newBatchedProxyException(_ code: String, title: String) -> BatchedProxyException {
        return BatchedProxyException(
            code: code,
            title: title,
            category: "",
            tags: [],
            expiresAt: 0,
            currency: "",
            maximum: 0.0,
            ratio: 0.0,
            approved: false,
            ceiling: 0.0,
            copay: 0.0,
            status: BatchedProxyExceptionStatus.proposed
        )
    }
}
