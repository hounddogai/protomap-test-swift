import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim group is in its life cycle.
    enum ClaimGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a claim group and its current status.
    final class ClaimGroup {
        var code: String
        var name: String
        var priority: Int
        var durationMinutes: Int
        var tags: [String]
        var attempts: Int
        var status: ClaimGroupStatus

        init(code: String, name: String, priority: Int, durationMinutes: Int, tags: [String], attempts: Int, status: ClaimGroupStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.durationMinutes = durationMinutes
            self.tags = tags
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimGroupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ClaimGroupStatus.running || next == ClaimGroupStatus.failed
            case .running:
                return next == ClaimGroupStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ClaimGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return ((Double(durationMinutes) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimGroup {
            return ClaimGroup(
                code: code,
                name: name,
                priority: priority,
                durationMinutes: durationMinutes,
                tags: tags,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim group in status new.
    static func newClaimGroup(_ code: String, name: String) -> ClaimGroup {
        return ClaimGroup(
            code: code,
            name: name,
            priority: 0,
            durationMinutes: 0,
            tags: [],
            attempts: 0,
            status: ClaimGroupStatus.new
        )
    }
}
