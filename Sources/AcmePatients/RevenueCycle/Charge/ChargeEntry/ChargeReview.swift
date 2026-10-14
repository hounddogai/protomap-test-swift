import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge review is in its life cycle.
    enum ChargeReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A charge review as the charge team keeps it.
    final class ChargeReview {
        var code: String
        var name: String
        var updatedAt: Int
        var version: Int
        var segment: String
        var summary: String
        var maximum: Double
        var status: ChargeReviewStatus

        init(code: String, name: String, updatedAt: Int, version: Int, segment: String, summary: String, maximum: Double, status: ChargeReviewStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.version = version
            self.segment = segment
            self.summary = summary
            self.maximum = maximum
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

        func canMoveTo(_ next: ChargeReviewStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ChargeReviewStatus.closed
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

        func moveTo(_ next: ChargeReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedVolume() -> Double {
            return ((Double(updatedAt) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> ChargeReview {
            return ChargeReview(
                code: code,
                name: name,
                updatedAt: updatedAt,
                version: version,
                segment: segment,
                summary: summary,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a charge review in status draft.
    static func newChargeReview(_ code: String, name: String) -> ChargeReview {
        return ChargeReview(
            code: code,
            name: name,
            updatedAt: 0,
            version: 0,
            segment: "",
            summary: "",
            maximum: 0.0,
            status: ChargeReviewStatus.draft
        )
    }
}
