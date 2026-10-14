import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal result override is in its life cycle.
    enum SeasonalResultOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a seasonal result override and its current status.
    final class SeasonalResultOverride {
        var code: String
        var title: String
        var summary: String
        var weight: Double
        var facility: String
        var segment: String
        var status: SeasonalResultOverrideStatus

        init(code: String, title: String, summary: String, weight: Double, facility: String, segment: String, status: SeasonalResultOverrideStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.weight = weight
            self.facility = facility
            self.segment = segment
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

        func canMoveTo(_ next: SeasonalResultOverrideStatus) -> Bool {
            switch status {
            case .idle:
                return next == SeasonalResultOverrideStatus.draining
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == SeasonalResultOverrideStatus.draining || next == SeasonalResultOverrideStatus.stopped
            case .draining:
                return next == SeasonalResultOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalResultOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal result override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal result override") \(code)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> SeasonalResultOverride {
            return SeasonalResultOverride(
                code: code,
                title: title,
                summary: summary,
                weight: weight,
                facility: facility,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a seasonal result override in status idle.
    static func newSeasonalResultOverride(_ code: String, title: String) -> SeasonalResultOverride {
        return SeasonalResultOverride(
            code: code,
            title: title,
            summary: "",
            weight: 0.0,
            facility: "",
            segment: "",
            status: SeasonalResultOverrideStatus.idle
        )
    }
}
