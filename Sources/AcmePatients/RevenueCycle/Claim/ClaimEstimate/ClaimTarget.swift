import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim target is in its life cycle.
    enum ClaimTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One claim target, with what the planners need to act on it.
    final class ClaimTarget {
        var code: String
        var name: String
        var quantity: Int
        var priority: Int
        var locale: String
        var region: String
        var category: String
        var status: ClaimTargetStatus

        init(code: String, name: String, quantity: Int, priority: Int, locale: String, region: String, category: String, status: ClaimTargetStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.priority = priority
            self.locale = locale
            self.region = region
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimTargetStatus) -> Bool {
            switch status {
            case .created:
                return next == ClaimTargetStatus.validated || next == ClaimTargetStatus.published
            case .validated:
                return next == ClaimTargetStatus.published || next == ClaimTargetStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ClaimTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("claim target") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(quantity) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimTarget {
            return ClaimTarget(
                code: code,
                name: name,
                quantity: quantity,
                priority: priority,
                locale: locale,
                region: region,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a claim target in status created.
    static func newClaimTarget(_ code: String, name: String) -> ClaimTarget {
        return ClaimTarget(
            code: code,
            name: name,
            quantity: 0,
            priority: 0,
            locale: "",
            region: "",
            category: "",
            status: ClaimTargetStatus.created
        )
    }
}
