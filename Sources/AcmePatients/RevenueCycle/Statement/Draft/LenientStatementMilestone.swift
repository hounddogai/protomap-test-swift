import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient statement milestone is in its life cycle.
    enum LenientStatementMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a lenient statement milestone and its current status.
    final class LenientStatementMilestone {
        var code: String
        var label: String
        var quantity: Int
        var refills: Int
        var threshold: Double
        var approved: Bool
        var maximum: Double
        var locale: String
        var endsAt: Int
        var ceiling: Double
        var status: LenientStatementMilestoneStatus

        init(code: String, label: String, quantity: Int, refills: Int, threshold: Double, approved: Bool, maximum: Double, locale: String, endsAt: Int, ceiling: Double, status: LenientStatementMilestoneStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.refills = refills
            self.threshold = threshold
            self.approved = approved
            self.maximum = maximum
            self.locale = locale
            self.endsAt = endsAt
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientStatementMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientStatementMilestoneStatus.granted || next == LenientStatementMilestoneStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: LenientStatementMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient statement milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveValue() -> Double {
            return ((Double(quantity) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> LenientStatementMilestone {
            return LenientStatementMilestone(
                code: code,
                label: label,
                quantity: quantity,
                refills: refills,
                threshold: threshold,
                approved: approved,
                maximum: maximum,
                locale: locale,
                endsAt: endsAt,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient statement milestone in status requested.
    static func newLenientStatementMilestone(_ code: String, label: String) -> LenientStatementMilestone {
        return LenientStatementMilestone(
            code: code,
            label: label,
            quantity: 0,
            refills: 0,
            threshold: 0.0,
            approved: false,
            maximum: 0.0,
            locale: "",
            endsAt: 0,
            ceiling: 0.0,
            status: LenientStatementMilestoneStatus.requested
        )
    }
}
