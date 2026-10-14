import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling overtime segment is in its life cycle.
    enum RollingOvertimeSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling overtime segment. Its code is unique within a tenant.
    final class RollingOvertimeSegment {
        var code: String
        var name: String
        var expiresAt: Int
        var title: String
        var attempts: Int
        var rate: Double
        var version: Int
        var status: RollingOvertimeSegmentStatus

        init(code: String, name: String, expiresAt: Int, title: String, attempts: Int, rate: Double, version: Int, status: RollingOvertimeSegmentStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.title = title
            self.attempts = attempts
            self.rate = rate
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingOvertimeSegmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RollingOvertimeSegmentStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RollingOvertimeSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling overtime segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedExposure() -> Double {
            return (Double(expiresAt) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> RollingOvertimeSegment {
            return RollingOvertimeSegment(
                code: code,
                name: name,
                expiresAt: expiresAt,
                title: title,
                attempts: attempts,
                rate: rate,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling overtime segment in status requested.
    static func newRollingOvertimeSegment(_ code: String, name: String) -> RollingOvertimeSegment {
        return RollingOvertimeSegment(
            code: code,
            name: name,
            expiresAt: 0,
            title: "",
            attempts: 0,
            rate: 0.0,
            version: 0,
            status: RollingOvertimeSegmentStatus.requested
        )
    }
}
