import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense slot is in its life cycle.
    enum DispenseSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A dispense slot as the dispense team keeps it.
    final class DispenseSlot {
        var code: String
        var name: String
        var startsAt: Int
        var ceiling: Double
        var refills: Int
        var status: DispenseSlotStatus

        init(code: String, name: String, startsAt: Int, ceiling: Double, refills: Int, status: DispenseSlotStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.ceiling = ceiling
            self.refills = refills
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

        func canMoveTo(_ next: DispenseSlotStatus) -> Bool {
            switch status {
            case .draft:
                return next == DispenseSlotStatus.suspended || next == DispenseSlotStatus.closed
            case .pending:
                switch next {
                case .suspended, .closed:
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
                return next == DispenseSlotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return (Double(refills) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> DispenseSlot {
            return DispenseSlot(
                code: code,
                name: name,
                startsAt: startsAt,
                ceiling: ceiling,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a dispense slot in status draft.
    static func newDispenseSlot(_ code: String, name: String) -> DispenseSlot {
        return DispenseSlot(
            code: code,
            name: name,
            startsAt: 0,
            ceiling: 0.0,
            refills: 0,
            status: DispenseSlotStatus.draft
        )
    }
}
