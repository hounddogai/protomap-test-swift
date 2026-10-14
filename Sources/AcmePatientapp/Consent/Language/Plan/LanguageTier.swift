import AcmePlatform
import Foundation

extension Consent {
    /// Where a language tier is in its life cycle.
    enum LanguageTierStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A language tier. Its code is unique within a tenant.
    final class LanguageTier {
        var code: String
        var title: String
        var windowDays: Int
        var channel: String
        var region: String
        var status: LanguageTierStatus

        init(code: String, title: String, windowDays: Int, channel: String, region: String, status: LanguageTierStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.channel = channel
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LanguageTierStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LanguageTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("language tier") \(code)"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> LanguageTier {
            return LanguageTier(
                code: code,
                title: title,
                windowDays: windowDays,
                channel: channel,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a language tier in status proposed.
    static func newLanguageTier(_ code: String, title: String) -> LanguageTier {
        return LanguageTier(
            code: code,
            title: title,
            windowDays: 0,
            channel: "",
            region: "",
            status: LanguageTierStatus.proposed
        )
    }
}
