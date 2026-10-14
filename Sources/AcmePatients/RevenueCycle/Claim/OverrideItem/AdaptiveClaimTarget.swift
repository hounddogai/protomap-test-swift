import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive claim target is in its life cycle.
    enum AdaptiveClaimTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One adaptive claim target, with what the planners need to act on it.
    final class AdaptiveClaimTarget {
        var code: String
        var name: String
        var discount: Double
        var maximum: Double
        var description: String
        var createdAt: Int
        var status: AdaptiveClaimTargetStatus

        init(code: String, name: String, discount: Double, maximum: Double, description: String, createdAt: Int, status: AdaptiveClaimTargetStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.maximum = maximum
            self.description = description
            self.createdAt = createdAt
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

        func canMoveTo(_ next: AdaptiveClaimTargetStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveClaimTargetStatus.active
            case .pending:
                return next == AdaptiveClaimTargetStatus.suspended
            case .active:
                return next == AdaptiveClaimTargetStatus.closed
            case .suspended:
                return next == AdaptiveClaimTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveClaimTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive claim target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netValue() -> Double {
            return ((Double(createdAt) - discount) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveClaimTarget {
            return AdaptiveClaimTarget(
                code: code,
                name: name,
                discount: discount,
                maximum: maximum,
                description: description,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive claim target in status draft.
    static func newAdaptiveClaimTarget(_ code: String, name: String) -> AdaptiveClaimTarget {
        return AdaptiveClaimTarget(
            code: code,
            name: name,
            discount: 0.0,
            maximum: 0.0,
            description: "",
            createdAt: 0,
            status: AdaptiveClaimTargetStatus.draft
        )
    }
}
