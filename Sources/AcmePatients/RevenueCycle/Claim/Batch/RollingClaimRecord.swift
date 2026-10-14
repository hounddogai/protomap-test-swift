import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling claim record is in its life cycle.
    enum RollingClaimRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One rolling claim record, with what the planners need to act on it.
    final class RollingClaimRecord {
        var code: String
        var name: String
        var segment: String
        var description: String
        var expiresAt: Int
        var approved: Bool
        var durationMinutes: Int
        var maximum: Double
        var visitMinutes: Int
        var status: RollingClaimRecordStatus

        init(code: String, name: String, segment: String, description: String, expiresAt: Int, approved: Bool, durationMinutes: Int, maximum: Double, visitMinutes: Int, status: RollingClaimRecordStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.description = description
            self.expiresAt = expiresAt
            self.approved = approved
            self.durationMinutes = durationMinutes
            self.maximum = maximum
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: RollingClaimRecordStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RollingClaimRecordStatus.running
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RollingClaimRecordStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingClaimRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling claim record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedLoad() -> Double {
            return ((Double(durationMinutes) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RollingClaimRecord {
            return RollingClaimRecord(
                code: code,
                name: name,
                segment: segment,
                description: description,
                expiresAt: expiresAt,
                approved: approved,
                durationMinutes: durationMinutes,
                maximum: maximum,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rolling claim record in status new.
    static func newRollingClaimRecord(_ code: String, name: String) -> RollingClaimRecord {
        return RollingClaimRecord(
            code: code,
            name: name,
            segment: "",
            description: "",
            expiresAt: 0,
            approved: false,
            durationMinutes: 0,
            maximum: 0.0,
            visitMinutes: 0,
            status: RollingClaimRecordStatus.new
        )
    }
}
