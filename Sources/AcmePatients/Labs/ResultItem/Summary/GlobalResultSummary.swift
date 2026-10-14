import AcmePlatform
import Foundation

extension Labs {
    /// Where a global result summary is in its life cycle.
    enum GlobalResultSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One global result summary, with what the planners need to act on it.
    final class GlobalResultSummary {
        var code: String
        var label: String
        var margin: Double
        var currency: String
        var payer: String
        var notes: String
        var channel: String
        var rate: Double
        var description: String
        var country: String
        var status: GlobalResultSummaryStatus

        init(code: String, label: String, margin: Double, currency: String, payer: String, notes: String, channel: String, rate: Double, description: String, country: String, status: GlobalResultSummaryStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.currency = currency
            self.payer = payer
            self.notes = notes
            self.channel = channel
            self.rate = rate
            self.description = description
            self.country = country
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

        func canMoveTo(_ next: GlobalResultSummaryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalResultSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global result summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedLoad() -> Double {
            return ((margin - rate) * 100).rounded() / 100
        }

        func copyValue() -> GlobalResultSummary {
            return GlobalResultSummary(
                code: code,
                label: label,
                margin: margin,
                currency: currency,
                payer: payer,
                notes: notes,
                channel: channel,
                rate: rate,
                description: description,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global result summary in status created.
    static func newGlobalResultSummary(_ code: String, label: String) -> GlobalResultSummary {
        return GlobalResultSummary(
            code: code,
            label: label,
            margin: 0.0,
            currency: "",
            payer: "",
            notes: "",
            channel: "",
            rate: 0.0,
            description: "",
            country: "",
            status: GlobalResultSummaryStatus.created
        )
    }
}
