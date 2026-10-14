import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read profile is in its life cycle.
    enum ReadProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One read profile, with what the planners need to act on it.
    final class ReadProfile {
        var code: String
        var title: String
        var expiresAt: Int
        var endsAt: Int
        var pinned: Bool
        var region: String
        var acuity: Int
        var procedureCode: String
        var attempts: Int
        var status: ReadProfileStatus

        init(code: String, title: String, expiresAt: Int, endsAt: Int, pinned: Bool, region: String, acuity: Int, procedureCode: String, attempts: Int, status: ReadProfileStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.endsAt = endsAt
            self.pinned = pinned
            self.region = region
            self.acuity = acuity
            self.procedureCode = procedureCode
            self.attempts = attempts
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

        func canMoveTo(_ next: ReadProfileStatus) -> Bool {
            switch status {
            case .planned:
                return next == ReadProfileStatus.scheduled || next == ReadProfileStatus.inProgress
            case .scheduled:
                return next == ReadProfileStatus.completed || next == ReadProfileStatus.cancelled
            case .inProgress:
                return next == ReadProfileStatus.completed
            case .completed:
                return next == ReadProfileStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedValue() -> Double {
            return ((Double(attempts) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ReadProfile {
            return ReadProfile(
                code: code,
                title: title,
                expiresAt: expiresAt,
                endsAt: endsAt,
                pinned: pinned,
                region: region,
                acuity: acuity,
                procedureCode: procedureCode,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a read profile in status planned.
    static func newReadProfile(_ code: String, title: String) -> ReadProfile {
        return ReadProfile(
            code: code,
            title: title,
            expiresAt: 0,
            endsAt: 0,
            pinned: false,
            region: "",
            acuity: 0,
            procedureCode: "",
            attempts: 0,
            status: ReadProfileStatus.planned
        )
    }
}
