import AcmePlatform
import Foundation

extension Labs {
    /// Where a global specimen ledger is in its life cycle.
    enum GlobalSpecimenLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One global specimen ledger, with what the planners need to act on it.
    final class GlobalSpecimenLedger {
        var code: String
        var title: String
        var floorValue: Double
        var label: String
        var capacity: Int
        var windowDays: Int
        var status: GlobalSpecimenLedgerStatus

        init(code: String, title: String, floorValue: Double, label: String, capacity: Int, windowDays: Int, status: GlobalSpecimenLedgerStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.label = label
            self.capacity = capacity
            self.windowDays = windowDays
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

        func canMoveTo(_ next: GlobalSpecimenLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == GlobalSpecimenLedgerStatus.closed
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

        func moveTo(_ next: GlobalSpecimenLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global specimen ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(capacity) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSpecimenLedger {
            return GlobalSpecimenLedger(
                code: code,
                title: title,
                floorValue: floorValue,
                label: label,
                capacity: capacity,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global specimen ledger in status draft.
    static func newGlobalSpecimenLedger(_ code: String, title: String) -> GlobalSpecimenLedger {
        return GlobalSpecimenLedger(
            code: code,
            title: title,
            floorValue: 0.0,
            label: "",
            capacity: 0,
            windowDays: 0,
            status: GlobalSpecimenLedgerStatus.draft
        )
    }
}
