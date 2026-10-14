import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal reference range profile is in its life cycle.
    enum SeasonalReferenceRangeProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One seasonal reference range profile, with what the planners need to act on it.
    final class SeasonalReferenceRangeProfile {
        var code: String
        var name: String
        var specialty: String
        var score: Double
        var limit: Int
        var graceDays: Int
        var status: SeasonalReferenceRangeProfileStatus

        init(code: String, name: String, specialty: String, score: Double, limit: Int, graceDays: Int, status: SeasonalReferenceRangeProfileStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.score = score
            self.limit = limit
            self.graceDays = graceDays
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

        func canMoveTo(_ next: SeasonalReferenceRangeProfileStatus) -> Bool {
            switch status {
            case .draft:
                return next == SeasonalReferenceRangeProfileStatus.closed
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SeasonalReferenceRangeProfileStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: SeasonalReferenceRangeProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal reference range profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal reference range profile") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(graceDays) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalReferenceRangeProfile {
            return SeasonalReferenceRangeProfile(
                code: code,
                name: name,
                specialty: specialty,
                score: score,
                limit: limit,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal reference range profile in status draft.
    static func newSeasonalReferenceRangeProfile(_ code: String, name: String) -> SeasonalReferenceRangeProfile {
        return SeasonalReferenceRangeProfile(
            code: code,
            name: name,
            specialty: "",
            score: 0.0,
            limit: 0,
            graceDays: 0,
            status: SeasonalReferenceRangeProfileStatus.draft
        )
    }
}
