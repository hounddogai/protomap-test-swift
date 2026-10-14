import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched skill mix cycle is in its life cycle.
    enum BatchedSkillMixCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched skill mix cycle as the skill mix team keeps it.
    final class BatchedSkillMixCycle {
        var code: String
        var title: String
        var attributes: [String: String]
        var threshold: Double
        var version: Int
        var acuity: Int
        var status: BatchedSkillMixCycleStatus

        init(code: String, title: String, attributes: [String: String], threshold: Double, version: Int, acuity: Int, status: BatchedSkillMixCycleStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.threshold = threshold
            self.version = version
            self.acuity = acuity
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

        func canMoveTo(_ next: BatchedSkillMixCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedSkillMixCycleStatus.pending
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == BatchedSkillMixCycleStatus.suspended || next == BatchedSkillMixCycleStatus.closed
            case .suspended:
                return next == BatchedSkillMixCycleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSkillMixCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched skill mix cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("batched skill mix cycle") \(code)"
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

        func weightedLoad() -> Double {
            return ((threshold + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSkillMixCycle {
            return BatchedSkillMixCycle(
                code: code,
                title: title,
                attributes: attributes,
                threshold: threshold,
                version: version,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched skill mix cycle in status draft.
    static func newBatchedSkillMixCycle(_ code: String, title: String) -> BatchedSkillMixCycle {
        return BatchedSkillMixCycle(
            code: code,
            title: title,
            attributes: [:],
            threshold: 0.0,
            version: 0,
            acuity: 0,
            status: BatchedSkillMixCycleStatus.draft
        )
    }
}
