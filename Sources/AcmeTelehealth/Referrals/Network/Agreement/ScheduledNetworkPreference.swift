import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled network preference is in its life cycle.
    enum ScheduledNetworkPreferenceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One scheduled network preference, with what the planners need to act on it.
    final class ScheduledNetworkPreference {
        var code: String
        var name: String
        var attempts: Int
        var title: String
        var summary: String
        var bed: String
        var locale: String
        var facility: String
        var status: ScheduledNetworkPreferenceStatus

        init(code: String, name: String, attempts: Int, title: String, summary: String, bed: String, locale: String, facility: String, status: ScheduledNetworkPreferenceStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.title = title
            self.summary = summary
            self.bed = bed
            self.locale = locale
            self.facility = facility
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

        func canMoveTo(_ next: ScheduledNetworkPreferenceStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledNetworkPreferenceStatus.validated || next == ScheduledNetworkPreferenceStatus.retired
            case .validated:
                return next == ScheduledNetworkPreferenceStatus.published
            case .published:
                return next == ScheduledNetworkPreferenceStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledNetworkPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled network preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> ScheduledNetworkPreference {
            return ScheduledNetworkPreference(
                code: code,
                name: name,
                attempts: attempts,
                title: title,
                summary: summary,
                bed: bed,
                locale: locale,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled network preference in status created.
    static func newScheduledNetworkPreference(_ code: String, name: String) -> ScheduledNetworkPreference {
        return ScheduledNetworkPreference(
            code: code,
            name: name,
            attempts: 0,
            title: "",
            summary: "",
            bed: "",
            locale: "",
            facility: "",
            status: ScheduledNetworkPreferenceStatus.created
        )
    }
}
