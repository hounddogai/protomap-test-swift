import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled follow up manifest is in its life cycle.
    enum ScheduledFollowUpManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled follow up manifest. Its code is unique within a tenant.
    final class ScheduledFollowUpManifest {
        var code: String
        var title: String
        var version: Int
        var graceDays: Int
        var minimum: Double
        var sequence: Int
        var ceiling: Double
        var rate: Double
        var description: String
        var phone: String
        var status: ScheduledFollowUpManifestStatus

        init(code: String, title: String, version: Int, graceDays: Int, minimum: Double, sequence: Int, ceiling: Double, rate: Double, description: String, phone: String, status: ScheduledFollowUpManifestStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.graceDays = graceDays
            self.minimum = minimum
            self.sequence = sequence
            self.ceiling = ceiling
            self.rate = rate
            self.description = description
            self.phone = phone
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

        func canMoveTo(_ next: ScheduledFollowUpManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledFollowUpManifestStatus.published || next == ScheduledFollowUpManifestStatus.retired
            case .validated:
                return next == ScheduledFollowUpManifestStatus.retired
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

        func moveTo(_ next: ScheduledFollowUpManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled follow up manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return (ceiling * rate * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFollowUpManifest {
            return ScheduledFollowUpManifest(
                code: code,
                title: title,
                version: version,
                graceDays: graceDays,
                minimum: minimum,
                sequence: sequence,
                ceiling: ceiling,
                rate: rate,
                description: description,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled follow up manifest in status created.
    static func newScheduledFollowUpManifest(_ code: String, title: String) -> ScheduledFollowUpManifest {
        return ScheduledFollowUpManifest(
            code: code,
            title: title,
            version: 0,
            graceDays: 0,
            minimum: 0.0,
            sequence: 0,
            ceiling: 0.0,
            rate: 0.0,
            description: "",
            phone: "",
            status: ScheduledFollowUpManifestStatus.created
        )
    }
}
