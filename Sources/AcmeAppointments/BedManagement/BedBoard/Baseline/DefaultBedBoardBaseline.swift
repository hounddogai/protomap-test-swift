import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default bed board baseline is in its life cycle.
    enum DefaultBedBoardBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a default bed board baseline and its current status.
    final class DefaultBedBoardBaseline {
        var code: String
        var name: String
        var acuity: Int
        var channel: String
        var country: String
        var endsAt: Int
        var locale: String
        var updatedAt: Int
        var graceDays: Int
        var retries: Int
        var status: DefaultBedBoardBaselineStatus

        init(code: String, name: String, acuity: Int, channel: String, country: String, endsAt: Int, locale: String, updatedAt: Int, graceDays: Int, retries: Int, status: DefaultBedBoardBaselineStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.channel = channel
            self.country = country
            self.endsAt = endsAt
            self.locale = locale
            self.updatedAt = updatedAt
            self.graceDays = graceDays
            self.retries = retries
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

        func canMoveTo(_ next: DefaultBedBoardBaselineStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DefaultBedBoardBaselineStatus.cancelled
            case .completed:
                return next == DefaultBedBoardBaselineStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultBedBoardBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default bed board baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return ((Double(updatedAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultBedBoardBaseline {
            return DefaultBedBoardBaseline(
                code: code,
                name: name,
                acuity: acuity,
                channel: channel,
                country: country,
                endsAt: endsAt,
                locale: locale,
                updatedAt: updatedAt,
                graceDays: graceDays,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a default bed board baseline in status planned.
    static func newDefaultBedBoardBaseline(_ code: String, name: String) -> DefaultBedBoardBaseline {
        return DefaultBedBoardBaseline(
            code: code,
            name: name,
            acuity: 0,
            channel: "",
            country: "",
            endsAt: 0,
            locale: "",
            updatedAt: 0,
            graceDays: 0,
            retries: 0,
            status: DefaultBedBoardBaselineStatus.planned
        )
    }
}
