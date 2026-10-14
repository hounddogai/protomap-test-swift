import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered task policy is in its life cycle.
    enum TieredTaskPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A tiered task policy. Its code is unique within a tenant.
    final class TieredTaskPolicy {
        var code: String
        var title: String
        var externalRef: String
        var score: Double
        var cost: Double
        var status: TieredTaskPolicyStatus

        init(code: String, title: String, externalRef: String, score: Double, cost: Double, status: TieredTaskPolicyStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.score = score
            self.cost = cost
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

        func canMoveTo(_ next: TieredTaskPolicyStatus) -> Bool {
            switch status {
            case .created:
                return next == TieredTaskPolicyStatus.retired
            case .validated:
                return next == TieredTaskPolicyStatus.retired
            case .published:
                return next == TieredTaskPolicyStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredTaskPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered task policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered task policy") \(code)"
        }

        func effectiveValue() -> Double {
            return ((cost + score) * 100).rounded() / 100
        }

        func copyValue() -> TieredTaskPolicy {
            return TieredTaskPolicy(
                code: code,
                title: title,
                externalRef: externalRef,
                score: score,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered task policy in status created.
    static func newTieredTaskPolicy(_ code: String, title: String) -> TieredTaskPolicy {
        return TieredTaskPolicy(
            code: code,
            title: title,
            externalRef: "",
            score: 0.0,
            cost: 0.0,
            status: TieredTaskPolicyStatus.created
        )
    }
}
