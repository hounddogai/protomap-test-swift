import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist rule is in its life cycle.
    enum WorklistRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One worklist rule, with what the planners need to act on it.
    final class WorklistRule {
        var code: String
        var name: String
        var batchSize: Int
        var ratio: Double
        var attempts: Int
        var tags: [String]
        var status: WorklistRuleStatus

        init(code: String, name: String, batchSize: Int, ratio: Double, attempts: Int, tags: [String], status: WorklistRuleStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.ratio = ratio
            self.attempts = attempts
            self.tags = tags
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

        func canMoveTo(_ next: WorklistRuleStatus) -> Bool {
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
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == WorklistRuleStatus.draining || next == WorklistRuleStatus.stopped
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

        func moveTo(_ next: WorklistRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("worklist rule") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((ratio + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistRule {
            return WorklistRule(
                code: code,
                name: name,
                batchSize: batchSize,
                ratio: ratio,
                attempts: attempts,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a worklist rule in status idle.
    static func newWorklistRule(_ code: String, name: String) -> WorklistRule {
        return WorklistRule(
            code: code,
            name: name,
            batchSize: 0,
            ratio: 0.0,
            attempts: 0,
            tags: [],
            status: WorklistRuleStatus.idle
        )
    }
}
