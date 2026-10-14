import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict courier policy is in its life cycle.
    enum StrictCourierPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One strict courier policy, with what the planners need to act on it.
    final class StrictCourierPolicy {
        var code: String
        var title: String
        var retries: Int
        var durationMinutes: Int
        var discount: Double
        var locale: String
        var channel: String
        var source: String
        var status: StrictCourierPolicyStatus

        init(code: String, title: String, retries: Int, durationMinutes: Int, discount: Double, locale: String, channel: String, source: String, status: StrictCourierPolicyStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.durationMinutes = durationMinutes
            self.discount = discount
            self.locale = locale
            self.channel = channel
            self.source = source
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

        func canMoveTo(_ next: StrictCourierPolicyStatus) -> Bool {
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

        func moveTo(_ next: StrictCourierPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict courier policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict courier policy") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(durationMinutes) - discount) * 100).rounded() / 100
        }

        func copyValue() -> StrictCourierPolicy {
            return StrictCourierPolicy(
                code: code,
                title: title,
                retries: retries,
                durationMinutes: durationMinutes,
                discount: discount,
                locale: locale,
                channel: channel,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict courier policy in status created.
    static func newStrictCourierPolicy(_ code: String, title: String) -> StrictCourierPolicy {
        return StrictCourierPolicy(
            code: code,
            title: title,
            retries: 0,
            durationMinutes: 0,
            discount: 0.0,
            locale: "",
            channel: "",
            source: "",
            status: StrictCourierPolicyStatus.created
        )
    }
}
