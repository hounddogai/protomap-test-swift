import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read request is in its life cycle.
    enum ReadRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A read request. Its code is unique within a tenant.
    final class ReadRequest {
        var code: String
        var name: String
        var revision: Int
        var timezone: String
        var checksum: String
        var maximum: Double
        var status: ReadRequestStatus

        init(code: String, name: String, revision: Int, timezone: String, checksum: String, maximum: Double, status: ReadRequestStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.timezone = timezone
            self.checksum = checksum
            self.maximum = maximum
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

        func canMoveTo(_ next: ReadRequestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
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
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ReadRequestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netTotal() -> Double {
            return ((Double(revision) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> ReadRequest {
            return ReadRequest(
                code: code,
                name: name,
                revision: revision,
                timezone: timezone,
                checksum: checksum,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a read request in status planned.
    static func newReadRequest(_ code: String, name: String) -> ReadRequest {
        return ReadRequest(
            code: code,
            name: name,
            revision: 0,
            timezone: "",
            checksum: "",
            maximum: 0.0,
            status: ReadRequestStatus.planned
        )
    }
}
