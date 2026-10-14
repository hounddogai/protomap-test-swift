import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient proxy review is in its life cycle.
    enum LenientProxyReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient proxy review as the proxy team keeps it.
    final class LenientProxyReview {
        var code: String
        var label: String
        var source: String
        var approved: Bool
        var visible: Bool
        var quantity: Int
        var timezone: String
        var category: String
        var weight: Double
        var status: LenientProxyReviewStatus

        init(code: String, label: String, source: String, approved: Bool, visible: Bool, quantity: Int, timezone: String, category: String, weight: Double, status: LenientProxyReviewStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.approved = approved
            self.visible = visible
            self.quantity = quantity
            self.timezone = timezone
            self.category = category
            self.weight = weight
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

        func canMoveTo(_ next: LenientProxyReviewStatus) -> Bool {
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
                return next == LenientProxyReviewStatus.stopped
            case .ready:
                return next == LenientProxyReviewStatus.stopped
            case .draining:
                return next == LenientProxyReviewStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientProxyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient proxy review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedTotal() -> Double {
            return ((Double(quantity) - weight) * 100).rounded() / 100
        }

        func copyValue() -> LenientProxyReview {
            return LenientProxyReview(
                code: code,
                label: label,
                source: source,
                approved: approved,
                visible: visible,
                quantity: quantity,
                timezone: timezone,
                category: category,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient proxy review in status idle.
    static func newLenientProxyReview(_ code: String, label: String) -> LenientProxyReview {
        return LenientProxyReview(
            code: code,
            label: label,
            source: "",
            approved: false,
            visible: false,
            quantity: 0,
            timezone: "",
            category: "",
            weight: 0.0,
            status: LenientProxyReviewStatus.idle
        )
    }
}
