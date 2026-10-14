import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled isolation digest is in its life cycle.
    enum ScheduledIsolationDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A scheduled isolation digest. Its code is unique within a tenant.
    final class ScheduledIsolationDigest {
        var code: String
        var title: String
        var clinicianID: String
        var floorValue: Double
        var active: Bool
        var graceDays: Int
        var status: ScheduledIsolationDigestStatus

        init(code: String, title: String, clinicianID: String, floorValue: Double, active: Bool, graceDays: Int, status: ScheduledIsolationDigestStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.floorValue = floorValue
            self.active = active
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ScheduledIsolationDigestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledIsolationDigestStatus.resolved || next == ScheduledIsolationDigestStatus.reopened
            case .inReview:
                return next == ScheduledIsolationDigestStatus.resolved || next == ScheduledIsolationDigestStatus.reopened
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ScheduledIsolationDigestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledIsolationDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled isolation digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled isolation digest") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(graceDays) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledIsolationDigest {
            return ScheduledIsolationDigest(
                code: code,
                title: title,
                clinicianID: clinicianID,
                floorValue: floorValue,
                active: active,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled isolation digest in status open.
    static func newScheduledIsolationDigest(_ code: String, title: String) -> ScheduledIsolationDigest {
        return ScheduledIsolationDigest(
            code: code,
            title: title,
            clinicianID: "",
            floorValue: 0.0,
            active: false,
            graceDays: 0,
            status: ScheduledIsolationDigestStatus.`open`
        )
    }
}
