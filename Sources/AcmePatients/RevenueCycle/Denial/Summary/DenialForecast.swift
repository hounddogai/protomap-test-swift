import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial forecast is in its life cycle.
    enum DenialForecastStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a denial forecast and its current status.
    final class DenialForecast {
        var code: String
        var name: String
        var channel: String
        var retries: Int
        var budget: Double
        var contactEmail: String
        var status: DenialForecastStatus

        init(code: String, name: String, channel: String, retries: Int, budget: Double, contactEmail: String, status: DenialForecastStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.retries = retries
            self.budget = budget
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: DenialForecastStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == DenialForecastStatus.suspended || next == DenialForecastStatus.closed
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

        func moveTo(_ next: DenialForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveLoad() -> Double {
            return ((budget - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> DenialForecast {
            return DenialForecast(
                code: code,
                name: name,
                channel: channel,
                retries: retries,
                budget: budget,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a denial forecast in status draft.
    static func newDenialForecast(_ code: String, name: String) -> DenialForecast {
        return DenialForecast(
            code: code,
            name: name,
            channel: "",
            retries: 0,
            budget: 0.0,
            contactEmail: "",
            status: DenialForecastStatus.draft
        )
    }
}
