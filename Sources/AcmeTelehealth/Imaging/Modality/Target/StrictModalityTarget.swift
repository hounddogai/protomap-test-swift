import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict modality target is in its life cycle.
    enum StrictModalityTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One strict modality target, with what the planners need to act on it.
    final class StrictModalityTarget {
        var code: String
        var label: String
        var timezone: String
        var updatedAt: Int
        var category: String
        var status: StrictModalityTargetStatus

        init(code: String, label: String, timezone: String, updatedAt: Int, category: String, status: StrictModalityTargetStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.updatedAt = updatedAt
            self.category = category
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

        func canMoveTo(_ next: StrictModalityTargetStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == StrictModalityTargetStatus.stopped
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

        func moveTo(_ next: StrictModalityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict modality target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> StrictModalityTarget {
            return StrictModalityTarget(
                code: code,
                label: label,
                timezone: timezone,
                updatedAt: updatedAt,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a strict modality target in status idle.
    static func newStrictModalityTarget(_ code: String, label: String) -> StrictModalityTarget {
        return StrictModalityTarget(
            code: code,
            label: label,
            timezone: "",
            updatedAt: 0,
            category: "",
            status: StrictModalityTargetStatus.idle
        )
    }
}
