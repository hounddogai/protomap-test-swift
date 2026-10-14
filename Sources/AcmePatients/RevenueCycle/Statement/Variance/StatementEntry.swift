import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement entry is in its life cycle.
    enum StatementEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One statement entry, with what the planners need to act on it.
    final class StatementEntry {
        var code: String
        var name: String
        var archived: Bool
        var budget: Double
        var batchSize: Int
        var ratio: Double
        var retries: Int
        var phone: String
        var status: StatementEntryStatus

        init(code: String, name: String, archived: Bool, budget: Double, batchSize: Int, ratio: Double, retries: Int, phone: String, status: StatementEntryStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.budget = budget
            self.batchSize = batchSize
            self.ratio = ratio
            self.retries = retries
            self.phone = phone
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

        func canMoveTo(_ next: StatementEntryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: StatementEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedVolume() -> Double {
            return ((ratio + budget) * 100).rounded() / 100
        }

        func copyValue() -> StatementEntry {
            return StatementEntry(
                code: code,
                name: name,
                archived: archived,
                budget: budget,
                batchSize: batchSize,
                ratio: ratio,
                retries: retries,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a statement entry in status idle.
    static func newStatementEntry(_ code: String, name: String) -> StatementEntry {
        return StatementEntry(
            code: code,
            name: name,
            archived: false,
            budget: 0.0,
            batchSize: 0,
            ratio: 0.0,
            retries: 0,
            phone: "",
            status: StatementEntryStatus.idle
        )
    }
}
