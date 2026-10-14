import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot rollup is in its life cycle.
    enum SlotRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One slot rollup, with what the planners need to act on it.
    final class SlotRollup {
        var code: String
        var title: String
        var cost: Double
        var segment: String
        var active: Bool
        var category: String
        var retries: Int
        var patientRef: String
        var status: SlotRollupStatus

        init(code: String, title: String, cost: Double, segment: String, active: Bool, category: String, retries: Int, patientRef: String, status: SlotRollupStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.segment = segment
            self.active = active
            self.category = category
            self.retries = retries
            self.patientRef = patientRef
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

        func canMoveTo(_ next: SlotRollupStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SlotRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveTotal() -> Double {
            return ((cost - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> SlotRollup {
            return SlotRollup(
                code: code,
                title: title,
                cost: cost,
                segment: segment,
                active: active,
                category: category,
                retries: retries,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a slot rollup in status draft.
    static func newSlotRollup(_ code: String, title: String) -> SlotRollup {
        return SlotRollup(
            code: code,
            title: title,
            cost: 0.0,
            segment: "",
            active: false,
            category: "",
            retries: 0,
            patientRef: "",
            status: SlotRollupStatus.draft
        )
    }
}
