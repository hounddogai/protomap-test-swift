import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global claim bundle is in its life cycle.
    enum GlobalClaimBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One global claim bundle, with what the planners need to act on it.
    final class GlobalClaimBundle {
        var code: String
        var name: String
        var archived: Bool
        var score: Double
        var pinned: Bool
        var status: GlobalClaimBundleStatus

        init(code: String, name: String, archived: Bool, score: Double, pinned: Bool, status: GlobalClaimBundleStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.score = score
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalClaimBundleStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalClaimBundleStatus.completed || next == GlobalClaimBundleStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == GlobalClaimBundleStatus.completed
            case .completed:
                return next == GlobalClaimBundleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalClaimBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global claim bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> GlobalClaimBundle {
            return GlobalClaimBundle(
                code: code,
                name: name,
                archived: archived,
                score: score,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global claim bundle in status planned.
    static func newGlobalClaimBundle(_ code: String, name: String) -> GlobalClaimBundle {
        return GlobalClaimBundle(
            code: code,
            name: name,
            archived: false,
            score: 0.0,
            pinned: false,
            status: GlobalClaimBundleStatus.planned
        )
    }
}
