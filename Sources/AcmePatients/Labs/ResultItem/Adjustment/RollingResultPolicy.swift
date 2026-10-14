import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling result policy is in its life cycle.
    enum RollingResultPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling result policy as the result team keeps it.
    final class RollingResultPolicy {
        var code: String
        var name: String
        var graceDays: Int
        var quantity: Int
        var archived: Bool
        var allergy: String
        var externalRef: String
        var windowDays: Int
        var unit: String
        var channel: String
        var procedureCode: String
        var status: RollingResultPolicyStatus

        init(code: String, name: String, graceDays: Int, quantity: Int, archived: Bool, allergy: String, externalRef: String, windowDays: Int, unit: String, channel: String, procedureCode: String, status: RollingResultPolicyStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.quantity = quantity
            self.archived = archived
            self.allergy = allergy
            self.externalRef = externalRef
            self.windowDays = windowDays
            self.unit = unit
            self.channel = channel
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: RollingResultPolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == RollingResultPolicyStatus.active
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RollingResultPolicyStatus.suspended || next == RollingResultPolicyStatus.closed
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

        func moveTo(_ next: RollingResultPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling result policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return ((Double(windowDays) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> RollingResultPolicy {
            return RollingResultPolicy(
                code: code,
                name: name,
                graceDays: graceDays,
                quantity: quantity,
                archived: archived,
                allergy: allergy,
                externalRef: externalRef,
                windowDays: windowDays,
                unit: unit,
                channel: channel,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rolling result policy in status draft.
    static func newRollingResultPolicy(_ code: String, name: String) -> RollingResultPolicy {
        return RollingResultPolicy(
            code: code,
            name: name,
            graceDays: 0,
            quantity: 0,
            archived: false,
            allergy: "",
            externalRef: "",
            windowDays: 0,
            unit: "",
            channel: "",
            procedureCode: "",
            status: RollingResultPolicyStatus.draft
        )
    }
}
