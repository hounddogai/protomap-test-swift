import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure target is in its life cycle.
    enum ClosureTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One closure target, with what the planners need to act on it.
    final class ClosureTarget {
        var code: String
        var title: String
        var locale: String
        var procedureCode: String
        var margin: Double
        var payer: String
        var graceDays: Int
        var amount: Double
        var status: ClosureTargetStatus

        init(code: String, title: String, locale: String, procedureCode: String, margin: Double, payer: String, graceDays: Int, amount: Double, status: ClosureTargetStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.procedureCode = procedureCode
            self.margin = margin
            self.payer = payer
            self.graceDays = graceDays
            self.amount = amount
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

        func canMoveTo(_ next: ClosureTargetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ClosureTargetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("closure target") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((margin - amount) * 100).rounded() / 100
        }

        func copyValue() -> ClosureTarget {
            return ClosureTarget(
                code: code,
                title: title,
                locale: locale,
                procedureCode: procedureCode,
                margin: margin,
                payer: payer,
                graceDays: graceDays,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a closure target in status requested.
    static func newClosureTarget(_ code: String, title: String) -> ClosureTarget {
        return ClosureTarget(
            code: code,
            title: title,
            locale: "",
            procedureCode: "",
            margin: 0.0,
            payer: "",
            graceDays: 0,
            amount: 0.0,
            status: ClosureTargetStatus.requested
        )
    }
}
