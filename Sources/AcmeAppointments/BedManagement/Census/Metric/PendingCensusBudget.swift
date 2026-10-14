import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending census budget is in its life cycle.
    enum PendingCensusBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending census budget, with what the planners need to act on it.
    final class PendingCensusBudget {
        var code: String
        var name: String
        var segment: String
        var source: String
        var category: String
        var visible: Bool
        var endsAt: Int
        var payer: String
        var status: PendingCensusBudgetStatus

        init(code: String, name: String, segment: String, source: String, category: String, visible: Bool, endsAt: Int, payer: String, status: PendingCensusBudgetStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.source = source
            self.category = category
            self.visible = visible
            self.endsAt = endsAt
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingCensusBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PendingCensusBudgetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCensusBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending census budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> PendingCensusBudget {
            return PendingCensusBudget(
                code: code,
                name: name,
                segment: segment,
                source: source,
                category: category,
                visible: visible,
                endsAt: endsAt,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a pending census budget in status proposed.
    static func newPendingCensusBudget(_ code: String, name: String) -> PendingCensusBudget {
        return PendingCensusBudget(
            code: code,
            name: name,
            segment: "",
            source: "",
            category: "",
            visible: false,
            endsAt: 0,
            payer: "",
            status: PendingCensusBudgetStatus.proposed
        )
    }
}
