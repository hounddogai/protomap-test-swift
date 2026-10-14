import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global closure forecast is in its life cycle.
    enum GlobalClosureForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One global closure forecast, with what the planners need to act on it.
    final class GlobalClosureForecast {
        var code: String
        var title: String
        var revision: Int
        var phone: String
        var windowDays: Int
        var status: GlobalClosureForecastStatus

        init(code: String, title: String, revision: Int, phone: String, windowDays: Int, status: GlobalClosureForecastStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.phone = phone
            self.windowDays = windowDays
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

        func canMoveTo(_ next: GlobalClosureForecastStatus) -> Bool {
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
                return next == GlobalClosureForecastStatus.published
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

        func moveTo(_ next: GlobalClosureForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global closure forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("global closure forecast") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(revision) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalClosureForecast {
            return GlobalClosureForecast(
                code: code,
                title: title,
                revision: revision,
                phone: phone,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global closure forecast in status created.
    static func newGlobalClosureForecast(_ code: String, title: String) -> GlobalClosureForecast {
        return GlobalClosureForecast(
            code: code,
            title: title,
            revision: 0,
            phone: "",
            windowDays: 0,
            status: GlobalClosureForecastStatus.created
        )
    }
}
