import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default dispense entry is in its life cycle.
    enum DefaultDispenseEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a default dispense entry and its current status.
    final class DefaultDispenseEntry {
        var code: String
        var name: String
        var ratio: Double
        var updatedAt: Int
        var archived: Bool
        var status: DefaultDispenseEntryStatus

        init(code: String, name: String, ratio: Double, updatedAt: Int, archived: Bool, status: DefaultDispenseEntryStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.updatedAt = updatedAt
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultDispenseEntryStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultDispenseEntryStatus.warming
            case .warming:
                return next == DefaultDispenseEntryStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DefaultDispenseEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default dispense entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedExposure() -> Double {
            return ((Double(updatedAt) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> DefaultDispenseEntry {
            return DefaultDispenseEntry(
                code: code,
                name: name,
                ratio: ratio,
                updatedAt: updatedAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default dispense entry in status idle.
    static func newDefaultDispenseEntry(_ code: String, name: String) -> DefaultDispenseEntry {
        return DefaultDispenseEntry(
            code: code,
            name: name,
            ratio: 0.0,
            updatedAt: 0,
            archived: false,
            status: DefaultDispenseEntryStatus.idle
        )
    }
}
