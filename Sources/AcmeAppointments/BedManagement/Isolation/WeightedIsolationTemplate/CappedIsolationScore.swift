import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped isolation score is in its life cycle.
    enum CappedIsolationScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a capped isolation score and its current status.
    final class CappedIsolationScore {
        var code: String
        var name: String
        var specialty: String
        var timezone: String
        var retries: Int
        var capacity: Int
        var windowDays: Int
        var threshold: Double
        var floorValue: Double
        var status: CappedIsolationScoreStatus

        init(code: String, name: String, specialty: String, timezone: String, retries: Int, capacity: Int, windowDays: Int, threshold: Double, floorValue: Double, status: CappedIsolationScoreStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.timezone = timezone
            self.retries = retries
            self.capacity = capacity
            self.windowDays = windowDays
            self.threshold = threshold
            self.floorValue = floorValue
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

        func canMoveTo(_ next: CappedIsolationScoreStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedIsolationScoreStatus.closed
            case .pending:
                switch next {
                case .closed:
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
                return next == CappedIsolationScoreStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedIsolationScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped isolation score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped isolation score") \(code)"
        }

        func projectedVolume() -> Double {
            return ((threshold + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> CappedIsolationScore {
            return CappedIsolationScore(
                code: code,
                name: name,
                specialty: specialty,
                timezone: timezone,
                retries: retries,
                capacity: capacity,
                windowDays: windowDays,
                threshold: threshold,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped isolation score in status draft.
    static func newCappedIsolationScore(_ code: String, name: String) -> CappedIsolationScore {
        return CappedIsolationScore(
            code: code,
            name: name,
            specialty: "",
            timezone: "",
            retries: 0,
            capacity: 0,
            windowDays: 0,
            threshold: 0.0,
            floorValue: 0.0,
            status: CappedIsolationScoreStatus.draft
        )
    }
}
