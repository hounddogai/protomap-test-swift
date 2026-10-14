import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global care gap allocation is in its life cycle.
    enum GlobalCareGapAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global care gap allocation as the care gap team keeps it.
    final class GlobalCareGapAllocation {
        var code: String
        var title: String
        var margin: Double
        var notes: String
        var ownerID: String
        var channel: String
        var startsAt: Int
        var status: GlobalCareGapAllocationStatus

        init(code: String, title: String, margin: Double, notes: String, ownerID: String, channel: String, startsAt: Int, status: GlobalCareGapAllocationStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.notes = notes
            self.ownerID = ownerID
            self.channel = channel
            self.startsAt = startsAt
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

        func canMoveTo(_ next: GlobalCareGapAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == GlobalCareGapAllocationStatus.inProgress || next == GlobalCareGapAllocationStatus.completed
            case .inProgress:
                return next == GlobalCareGapAllocationStatus.completed || next == GlobalCareGapAllocationStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: GlobalCareGapAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global care gap allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global care gap allocation") \(code)"
        }

        func weightedVolume() -> Double {
            return ((margin + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCareGapAllocation {
            return GlobalCareGapAllocation(
                code: code,
                title: title,
                margin: margin,
                notes: notes,
                ownerID: ownerID,
                channel: channel,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global care gap allocation in status planned.
    static func newGlobalCareGapAllocation(_ code: String, title: String) -> GlobalCareGapAllocation {
        return GlobalCareGapAllocation(
            code: code,
            title: title,
            margin: 0.0,
            notes: "",
            ownerID: "",
            channel: "",
            startsAt: 0,
            status: GlobalCareGapAllocationStatus.planned
        )
    }
}
