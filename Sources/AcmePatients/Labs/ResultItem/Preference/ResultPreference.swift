import AcmePlatform
import Foundation

extension Labs {
    /// Where a result preference is in its life cycle.
    enum ResultPreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A result preference as the result team keeps it.
    final class ResultPreference {
        var code: String
        var title: String
        var createdAt: Int
        var channel: String
        var timezone: String
        var active: Bool
        var acuity: Int
        var version: Int
        var locale: String
        var status: ResultPreferenceStatus

        init(code: String, title: String, createdAt: Int, channel: String, timezone: String, active: Bool, acuity: Int, version: Int, locale: String, status: ResultPreferenceStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.channel = channel
            self.timezone = timezone
            self.active = active
            self.acuity = acuity
            self.version = version
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultPreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ResultPreferenceStatus.reopened || next == ResultPreferenceStatus.archived
            case .reopened:
                return next == ResultPreferenceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedTotal() -> Double {
            return (Double(version) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> ResultPreference {
            return ResultPreference(
                code: code,
                title: title,
                createdAt: createdAt,
                channel: channel,
                timezone: timezone,
                active: active,
                acuity: acuity,
                version: version,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a result preference in status open.
    static func newResultPreference(_ code: String, title: String) -> ResultPreference {
        return ResultPreference(
            code: code,
            title: title,
            createdAt: 0,
            channel: "",
            timezone: "",
            active: false,
            acuity: 0,
            version: 0,
            locale: "",
            status: ResultPreferenceStatus.`open`
        )
    }
}
