import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict courier target is in its life cycle.
    enum StrictCourierTargetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict courier target as the courier team keeps it.
    final class StrictCourierTarget {
        var code: String
        var name: String
        var updatedAt: Int
        var reviewer: String
        var visitMinutes: Int
        var status: StrictCourierTargetStatus

        init(code: String, name: String, updatedAt: Int, reviewer: String, visitMinutes: Int, status: StrictCourierTargetStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.reviewer = reviewer
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: StrictCourierTargetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == StrictCourierTargetStatus.done || next == StrictCourierTargetStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StrictCourierTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict courier target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveVolume() -> Double {
            return ((Double(updatedAt) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StrictCourierTarget {
            return StrictCourierTarget(
                code: code,
                name: name,
                updatedAt: updatedAt,
                reviewer: reviewer,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict courier target in status new.
    static func newStrictCourierTarget(_ code: String, name: String) -> StrictCourierTarget {
        return StrictCourierTarget(
            code: code,
            name: name,
            updatedAt: 0,
            reviewer: "",
            visitMinutes: 0,
            status: StrictCourierTargetStatus.new
        )
    }
}
