import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation segment is in its life cycle.
    enum IsolationSegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A isolation segment as the isolation team keeps it.
    final class IsolationSegment {
        var code: String
        var title: String
        var attempts: Int
        var notes: String
        var version: Int
        var country: String
        var clinicianID: String
        var status: IsolationSegmentStatus

        init(code: String, title: String, attempts: Int, notes: String, version: Int, country: String, clinicianID: String, status: IsolationSegmentStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.notes = notes
            self.version = version
            self.country = country
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: IsolationSegmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == IsolationSegmentStatus.inProgress || next == IsolationSegmentStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: IsolationSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedValue() -> Double {
            return ((Double(attempts) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> IsolationSegment {
            return IsolationSegment(
                code: code,
                title: title,
                attempts: attempts,
                notes: notes,
                version: version,
                country: country,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a isolation segment in status planned.
    static func newIsolationSegment(_ code: String, title: String) -> IsolationSegment {
        return IsolationSegment(
            code: code,
            title: title,
            attempts: 0,
            notes: "",
            version: 0,
            country: "",
            clinicianID: "",
            status: IsolationSegmentStatus.planned
        )
    }
}
