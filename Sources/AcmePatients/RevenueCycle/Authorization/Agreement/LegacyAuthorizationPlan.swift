import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy authorization plan is in its life cycle.
    enum LegacyAuthorizationPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a legacy authorization plan and its current status.
    final class LegacyAuthorizationPlan {
        var code: String
        var name: String
        var externalRef: String
        var sequence: Int
        var segment: String
        var status: LegacyAuthorizationPlanStatus

        init(code: String, name: String, externalRef: String, sequence: Int, segment: String, status: LegacyAuthorizationPlanStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.sequence = sequence
            self.segment = segment
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

        func canMoveTo(_ next: LegacyAuthorizationPlanStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyAuthorizationPlanStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LegacyAuthorizationPlanStatus.suspended || next == LegacyAuthorizationPlanStatus.closed
            case .suspended:
                return next == LegacyAuthorizationPlanStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAuthorizationPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy authorization plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> LegacyAuthorizationPlan {
            return LegacyAuthorizationPlan(
                code: code,
                name: name,
                externalRef: externalRef,
                sequence: sequence,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy authorization plan in status draft.
    static func newLegacyAuthorizationPlan(_ code: String, name: String) -> LegacyAuthorizationPlan {
        return LegacyAuthorizationPlan(
            code: code,
            name: name,
            externalRef: "",
            sequence: 0,
            segment: "",
            status: LegacyAuthorizationPlanStatus.draft
        )
    }
}
