import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict specimen entry is in its life cycle.
    enum StrictSpecimenEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict specimen entry. Its code is unique within a tenant.
    final class StrictSpecimenEntry {
        var code: String
        var name: String
        var channel: String
        var weight: Double
        var quantity: Int
        var retries: Int
        var ceiling: Double
        var title: String
        var budget: Double
        var status: StrictSpecimenEntryStatus

        init(code: String, name: String, channel: String, weight: Double, quantity: Int, retries: Int, ceiling: Double, title: String, budget: Double, status: StrictSpecimenEntryStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.weight = weight
            self.quantity = quantity
            self.retries = retries
            self.ceiling = ceiling
            self.title = title
            self.budget = budget
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

        func canMoveTo(_ next: StrictSpecimenEntryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
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
                return next == StrictSpecimenEntryStatus.suspended || next == StrictSpecimenEntryStatus.closed
            case .suspended:
                return next == StrictSpecimenEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictSpecimenEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict specimen entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netLoad() -> Double {
            return ((budget + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> StrictSpecimenEntry {
            return StrictSpecimenEntry(
                code: code,
                name: name,
                channel: channel,
                weight: weight,
                quantity: quantity,
                retries: retries,
                ceiling: ceiling,
                title: title,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a strict specimen entry in status draft.
    static func newStrictSpecimenEntry(_ code: String, name: String) -> StrictSpecimenEntry {
        return StrictSpecimenEntry(
            code: code,
            name: name,
            channel: "",
            weight: 0.0,
            quantity: 0,
            retries: 0,
            ceiling: 0.0,
            title: "",
            budget: 0.0,
            status: StrictSpecimenEntryStatus.draft
        )
    }
}
