import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending skill mix score is in its life cycle.
    enum PendingSkillMixScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending skill mix score as the skill mix team keeps it.
    final class PendingSkillMixScore {
        var code: String
        var name: String
        var ceiling: Double
        var attributes: [String: String]
        var capacity: Int
        var status: PendingSkillMixScoreStatus

        init(code: String, name: String, ceiling: Double, attributes: [String: String], capacity: Int, status: PendingSkillMixScoreStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.attributes = attributes
            self.capacity = capacity
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

        func canMoveTo(_ next: PendingSkillMixScoreStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PendingSkillMixScoreStatus.done || next == PendingSkillMixScoreStatus.failed
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

        func moveTo(_ next: PendingSkillMixScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending skill mix score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending skill mix score") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedValue() -> Double {
            return ((ceiling - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingSkillMixScore {
            return PendingSkillMixScore(
                code: code,
                name: name,
                ceiling: ceiling,
                attributes: attributes,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending skill mix score in status new.
    static func newPendingSkillMixScore(_ code: String, name: String) -> PendingSkillMixScore {
        return PendingSkillMixScore(
            code: code,
            name: name,
            ceiling: 0.0,
            attributes: [:],
            capacity: 0,
            status: PendingSkillMixScoreStatus.new
        )
    }
}
