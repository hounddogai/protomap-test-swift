import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set entry is in its life cycle.
    enum OrderSetEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A order set entry. Its code is unique within a tenant.
    final class OrderSetEntry {
        var code: String
        var name: String
        var score: Double
        var attempts: Int
        var startsAt: Int
        var status: OrderSetEntryStatus

        init(code: String, name: String, score: Double, attempts: Int, startsAt: Int, status: OrderSetEntryStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.attempts = attempts
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OrderSetEntryStatus) -> Bool {
            switch status {
            case .`open`:
                return next == OrderSetEntryStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == OrderSetEntryStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: OrderSetEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netLoad() -> Double {
            return (Double(attempts) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetEntry {
            return OrderSetEntry(
                code: code,
                name: name,
                score: score,
                attempts: attempts,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a order set entry in status open.
    static func newOrderSetEntry(_ code: String, name: String) -> OrderSetEntry {
        return OrderSetEntry(
            code: code,
            name: name,
            score: 0.0,
            attempts: 0,
            startsAt: 0,
            status: OrderSetEntryStatus.`open`
        )
    }
}
