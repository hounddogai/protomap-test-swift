import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist summary is in its life cycle.
    enum WorklistSummaryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a worklist summary and its current status.
    final class WorklistSummary {
        var code: String
        var title: String
        var active: Bool
        var sequence: Int
        var payer: String
        var description: String
        var expiresAt: Int
        var status: WorklistSummaryStatus

        init(code: String, title: String, active: Bool, sequence: Int, payer: String, description: String, expiresAt: Int, status: WorklistSummaryStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.sequence = sequence
            self.payer = payer
            self.description = description
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: WorklistSummaryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == WorklistSummaryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("worklist summary") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(sequence) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistSummary {
            return WorklistSummary(
                code: code,
                title: title,
                active: active,
                sequence: sequence,
                payer: payer,
                description: description,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a worklist summary in status planned.
    static func newWorklistSummary(_ code: String, title: String) -> WorklistSummary {
        return WorklistSummary(
            code: code,
            title: title,
            active: false,
            sequence: 0,
            payer: "",
            description: "",
            expiresAt: 0,
            status: WorklistSummaryStatus.planned
        )
    }
}
