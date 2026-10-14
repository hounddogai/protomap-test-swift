import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier segment is in its life cycle.
    enum CourierSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A courier segment as the courier team keeps it.
    final class CourierSegment {
        var code: String
        var title: String
        var minimum: Double
        var retries: Int
        var revision: Int
        var status: CourierSegmentStatus

        init(code: String, title: String, minimum: Double, retries: Int, revision: Int, status: CourierSegmentStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.retries = retries
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == CourierSegmentStatus.closed
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CourierSegmentStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CourierSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("courier segment") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(revision) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> CourierSegment {
            return CourierSegment(
                code: code,
                title: title,
                minimum: minimum,
                retries: retries,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a courier segment in status draft.
    static func newCourierSegment(_ code: String, title: String) -> CourierSegment {
        return CourierSegment(
            code: code,
            title: title,
            minimum: 0.0,
            retries: 0,
            revision: 0,
            status: CourierSegmentStatus.draft
        )
    }
}
