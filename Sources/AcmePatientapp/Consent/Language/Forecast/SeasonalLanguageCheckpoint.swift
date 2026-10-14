import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal language checkpoint is in its life cycle.
    enum SeasonalLanguageCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A seasonal language checkpoint as the language team keeps it.
    final class SeasonalLanguageCheckpoint {
        var code: String
        var title: String
        var version: Int
        var minimum: Double
        var approved: Bool
        var status: SeasonalLanguageCheckpointStatus

        init(code: String, title: String, version: Int, minimum: Double, approved: Bool, status: SeasonalLanguageCheckpointStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.minimum = minimum
            self.approved = approved
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

        func canMoveTo(_ next: SeasonalLanguageCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == SeasonalLanguageCheckpointStatus.scheduled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == SeasonalLanguageCheckpointStatus.completed || next == SeasonalLanguageCheckpointStatus.cancelled
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

        func moveTo(_ next: SeasonalLanguageCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal language checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedLoad() -> Double {
            return ((Double(version) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalLanguageCheckpoint {
            return SeasonalLanguageCheckpoint(
                code: code,
                title: title,
                version: version,
                minimum: minimum,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal language checkpoint in status planned.
    static func newSeasonalLanguageCheckpoint(_ code: String, title: String) -> SeasonalLanguageCheckpoint {
        return SeasonalLanguageCheckpoint(
            code: code,
            title: title,
            version: 0,
            minimum: 0.0,
            approved: false,
            status: SeasonalLanguageCheckpointStatus.planned
        )
    }
}
