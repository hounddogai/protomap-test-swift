import AcmePlatform
import Foundation

extension Labs {
    /// Where a global courier tier is in its life cycle.
    enum GlobalCourierTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a global courier tier and its current status.
    final class GlobalCourierTier {
        var code: String
        var title: String
        var notes: String
        var timezone: String
        var updatedAt: Int
        var weight: Double
        var channel: String
        var source: String
        var score: Double
        var category: String
        var status: GlobalCourierTierStatus

        init(code: String, title: String, notes: String, timezone: String, updatedAt: Int, weight: Double, channel: String, source: String, score: Double, category: String, status: GlobalCourierTierStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.timezone = timezone
            self.updatedAt = updatedAt
            self.weight = weight
            self.channel = channel
            self.source = source
            self.score = score
            self.category = category
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

        func canMoveTo(_ next: GlobalCourierTierStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == GlobalCourierTierStatus.inProgress || next == GlobalCourierTierStatus.completed
            case .inProgress:
                return next == GlobalCourierTierStatus.completed
            case .completed:
                return next == GlobalCourierTierStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCourierTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global courier tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global courier tier") \(code)"
        }

        func netTotal() -> Double {
            return ((score + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCourierTier {
            return GlobalCourierTier(
                code: code,
                title: title,
                notes: notes,
                timezone: timezone,
                updatedAt: updatedAt,
                weight: weight,
                channel: channel,
                source: source,
                score: score,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global courier tier in status planned.
    static func newGlobalCourierTier(_ code: String, title: String) -> GlobalCourierTier {
        return GlobalCourierTier(
            code: code,
            title: title,
            notes: "",
            timezone: "",
            updatedAt: 0,
            weight: 0.0,
            channel: "",
            source: "",
            score: 0.0,
            category: "",
            status: GlobalCourierTierStatus.planned
        )
    }
}
