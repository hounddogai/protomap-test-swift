import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient dispense baseline is in its life cycle.
    enum LenientDispenseBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient dispense baseline. Its code is unique within a tenant.
    final class LenientDispenseBaseline {
        var code: String
        var label: String
        var currency: String
        var endsAt: Int
        var limit: Int
        var ceiling: Double
        var status: LenientDispenseBaselineStatus

        init(code: String, label: String, currency: String, endsAt: Int, limit: Int, ceiling: Double, status: LenientDispenseBaselineStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.endsAt = endsAt
            self.limit = limit
            self.ceiling = ceiling
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

        func canMoveTo(_ next: LenientDispenseBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientDispenseBaselineStatus.reopened || next == LenientDispenseBaselineStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LenientDispenseBaselineStatus.reopened
            case .reopened:
                return next == LenientDispenseBaselineStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientDispenseBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient dispense baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return ((Double(endsAt) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> LenientDispenseBaseline {
            return LenientDispenseBaseline(
                code: code,
                label: label,
                currency: currency,
                endsAt: endsAt,
                limit: limit,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient dispense baseline in status open.
    static func newLenientDispenseBaseline(_ code: String, label: String) -> LenientDispenseBaseline {
        return LenientDispenseBaseline(
            code: code,
            label: label,
            currency: "",
            endsAt: 0,
            limit: 0,
            ceiling: 0.0,
            status: LenientDispenseBaselineStatus.`open`
        )
    }
}
