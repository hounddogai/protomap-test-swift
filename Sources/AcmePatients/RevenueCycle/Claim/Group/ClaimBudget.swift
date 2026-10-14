import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim budget is in its life cycle.
    enum ClaimBudgetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One claim budget, with what the planners need to act on it.
    final class ClaimBudget {
        var code: String
        var title: String
        var notes: String
        var startsAt: Int
        var capacity: Int
        var score: Double
        var updatedAt: Int
        var encounterID: String
        var tags: [String]
        var externalRef: String
        var minimum: Double
        var status: ClaimBudgetStatus

        init(code: String, title: String, notes: String, startsAt: Int, capacity: Int, score: Double, updatedAt: Int, encounterID: String, tags: [String], externalRef: String, minimum: Double, status: ClaimBudgetStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.startsAt = startsAt
            self.capacity = capacity
            self.score = score
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.tags = tags
            self.externalRef = externalRef
            self.minimum = minimum
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

        func canMoveTo(_ next: ClaimBudgetStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ClaimBudgetStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ClaimBudgetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netValue() -> Double {
            return ((Double(capacity) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimBudget {
            return ClaimBudget(
                code: code,
                title: title,
                notes: notes,
                startsAt: startsAt,
                capacity: capacity,
                score: score,
                updatedAt: updatedAt,
                encounterID: encounterID,
                tags: tags,
                externalRef: externalRef,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a claim budget in status idle.
    static func newClaimBudget(_ code: String, title: String) -> ClaimBudget {
        return ClaimBudget(
            code: code,
            title: title,
            notes: "",
            startsAt: 0,
            capacity: 0,
            score: 0.0,
            updatedAt: 0,
            encounterID: "",
            tags: [],
            externalRef: "",
            minimum: 0.0,
            status: ClaimBudgetStatus.idle
        )
    }
}
