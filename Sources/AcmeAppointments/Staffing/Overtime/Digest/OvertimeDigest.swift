import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime digest is in its life cycle.
    enum OvertimeDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One overtime digest, with what the planners need to act on it.
    final class OvertimeDigest {
        var code: String
        var title: String
        var summary: String
        var ward: String
        var createdAt: Int
        var unit: String
        var status: OvertimeDigestStatus

        init(code: String, title: String, summary: String, ward: String, createdAt: Int, unit: String, status: OvertimeDigestStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.ward = ward
            self.createdAt = createdAt
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OvertimeDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == OvertimeDigestStatus.queued || next == OvertimeDigestStatus.done
            case .queued:
                return next == OvertimeDigestStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: OvertimeDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("overtime digest") \(code)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> OvertimeDigest {
            return OvertimeDigest(
                code: code,
                title: title,
                summary: summary,
                ward: ward,
                createdAt: createdAt,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a overtime digest in status new.
    static func newOvertimeDigest(_ code: String, title: String) -> OvertimeDigest {
        return OvertimeDigest(
            code: code,
            title: title,
            summary: "",
            ward: "",
            createdAt: 0,
            unit: "",
            status: OvertimeDigestStatus.new
        )
    }
}
