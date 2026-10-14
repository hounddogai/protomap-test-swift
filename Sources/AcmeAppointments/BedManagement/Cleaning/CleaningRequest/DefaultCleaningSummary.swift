import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default cleaning summary is in its life cycle.
    enum DefaultCleaningSummaryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a default cleaning summary and its current status.
    final class DefaultCleaningSummary {
        var code: String
        var label: String
        var score: Double
        var attempts: Int
        var archived: Bool
        var source: String
        var specialty: String
        var ownerID: String
        var status: DefaultCleaningSummaryStatus

        init(code: String, label: String, score: Double, attempts: Int, archived: Bool, source: String, specialty: String, ownerID: String, status: DefaultCleaningSummaryStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.attempts = attempts
            self.archived = archived
            self.source = source
            self.specialty = specialty
            self.ownerID = ownerID
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

        func canMoveTo(_ next: DefaultCleaningSummaryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DefaultCleaningSummaryStatus.completed
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

        func moveTo(_ next: DefaultCleaningSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default cleaning summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedVolume() -> Double {
            return (score * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCleaningSummary {
            return DefaultCleaningSummary(
                code: code,
                label: label,
                score: score,
                attempts: attempts,
                archived: archived,
                source: source,
                specialty: specialty,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default cleaning summary in status planned.
    static func newDefaultCleaningSummary(_ code: String, label: String) -> DefaultCleaningSummary {
        return DefaultCleaningSummary(
            code: code,
            label: label,
            score: 0.0,
            attempts: 0,
            archived: false,
            source: "",
            specialty: "",
            ownerID: "",
            status: DefaultCleaningSummaryStatus.planned
        )
    }
}
