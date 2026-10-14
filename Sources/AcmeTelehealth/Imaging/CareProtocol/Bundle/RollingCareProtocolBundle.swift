import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling care protocol bundle is in its life cycle.
    enum RollingCareProtocolBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a rolling care protocol bundle and its current status.
    final class RollingCareProtocolBundle {
        var code: String
        var title: String
        var summary: String
        var country: String
        var bed: String
        var graceDays: Int
        var status: RollingCareProtocolBundleStatus

        init(code: String, title: String, summary: String, country: String, bed: String, graceDays: Int, status: RollingCareProtocolBundleStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.country = country
            self.bed = bed
            self.graceDays = graceDays
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

        func canMoveTo(_ next: RollingCareProtocolBundleStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingCareProtocolBundleStatus.validated
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RollingCareProtocolBundleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCareProtocolBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care protocol bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling care protocol bundle") \(code)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> RollingCareProtocolBundle {
            return RollingCareProtocolBundle(
                code: code,
                title: title,
                summary: summary,
                country: country,
                bed: bed,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling care protocol bundle in status created.
    static func newRollingCareProtocolBundle(_ code: String, title: String) -> RollingCareProtocolBundle {
        return RollingCareProtocolBundle(
            code: code,
            title: title,
            summary: "",
            country: "",
            bed: "",
            graceDays: 0,
            status: RollingCareProtocolBundleStatus.created
        )
    }
}
