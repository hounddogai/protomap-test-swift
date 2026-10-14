import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal closure checkpoint is in its life cycle.
    enum SeasonalClosureCheckpointStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A seasonal closure checkpoint. Its code is unique within a tenant.
    final class SeasonalClosureCheckpoint {
        var code: String
        var title: String
        var channel: String
        var ward: String
        var windowDays: Int
        var maximum: Double
        var status: SeasonalClosureCheckpointStatus

        init(code: String, title: String, channel: String, ward: String, windowDays: Int, maximum: Double, status: SeasonalClosureCheckpointStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.ward = ward
            self.windowDays = windowDays
            self.maximum = maximum
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

        func canMoveTo(_ next: SeasonalClosureCheckpointStatus) -> Bool {
            switch status {
            case .draft:
                return next == SeasonalClosureCheckpointStatus.closed
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SeasonalClosureCheckpointStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalClosureCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal closure checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return (Double(windowDays) * maximum * 100).rounded() / 100
        }

        func copyValue() -> SeasonalClosureCheckpoint {
            return SeasonalClosureCheckpoint(
                code: code,
                title: title,
                channel: channel,
                ward: ward,
                windowDays: windowDays,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a seasonal closure checkpoint in status draft.
    static func newSeasonalClosureCheckpoint(_ code: String, title: String) -> SeasonalClosureCheckpoint {
        return SeasonalClosureCheckpoint(
            code: code,
            title: title,
            channel: "",
            ward: "",
            windowDays: 0,
            maximum: 0.0,
            status: SeasonalClosureCheckpointStatus.draft
        )
    }
}
