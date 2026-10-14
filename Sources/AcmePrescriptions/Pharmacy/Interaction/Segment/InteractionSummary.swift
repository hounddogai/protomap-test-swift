import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction summary is in its life cycle.
    enum InteractionSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A interaction summary as the interaction team keeps it.
    final class InteractionSummary {
        var code: String
        var title: String
        var windowDays: Int
        var maximum: Double
        var weight: Double
        var revision: Int
        var graceDays: Int
        var rate: Double
        var checksum: String
        var copay: Double
        var durationMinutes: Int
        var status: InteractionSummaryStatus

        init(code: String, title: String, windowDays: Int, maximum: Double, weight: Double, revision: Int, graceDays: Int, rate: Double, checksum: String, copay: Double, durationMinutes: Int, status: InteractionSummaryStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.maximum = maximum
            self.weight = weight
            self.revision = revision
            self.graceDays = graceDays
            self.rate = rate
            self.checksum = checksum
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InteractionSummaryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == InteractionSummaryStatus.published || next == InteractionSummaryStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: InteractionSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return (Double(durationMinutes) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> InteractionSummary {
            return InteractionSummary(
                code: code,
                title: title,
                windowDays: windowDays,
                maximum: maximum,
                weight: weight,
                revision: revision,
                graceDays: graceDays,
                rate: rate,
                checksum: checksum,
                copay: copay,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a interaction summary in status created.
    static func newInteractionSummary(_ code: String, title: String) -> InteractionSummary {
        return InteractionSummary(
            code: code,
            title: title,
            windowDays: 0,
            maximum: 0.0,
            weight: 0.0,
            revision: 0,
            graceDays: 0,
            rate: 0.0,
            checksum: "",
            copay: 0.0,
            durationMinutes: 0,
            status: InteractionSummaryStatus.created
        )
    }
}
