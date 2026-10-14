import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal study digest is in its life cycle.
    enum SeasonalStudyDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One seasonal study digest, with what the planners need to act on it.
    final class SeasonalStudyDigest {
        var code: String
        var label: String
        var notes: String
        var rate: Double
        var attempts: Int
        var status: SeasonalStudyDigestStatus

        init(code: String, label: String, notes: String, rate: Double, attempts: Int, status: SeasonalStudyDigestStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.rate = rate
            self.attempts = attempts
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

        func canMoveTo(_ next: SeasonalStudyDigestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalStudyDigestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalStudyDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal study digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedLoad() -> Double {
            return ((rate + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalStudyDigest {
            return SeasonalStudyDigest(
                code: code,
                label: label,
                notes: notes,
                rate: rate,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal study digest in status new.
    static func newSeasonalStudyDigest(_ code: String, label: String) -> SeasonalStudyDigest {
        return SeasonalStudyDigest(
            code: code,
            label: label,
            notes: "",
            rate: 0.0,
            attempts: 0,
            status: SeasonalStudyDigestStatus.new
        )
    }
}
