import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning assignment is in its life cycle.
    enum CleaningAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A cleaning assignment. Its code is unique within a tenant.
    final class CleaningAssignment {
        var code: String
        var name: String
        var expiresAt: Int
        var retries: Int
        var version: Int
        var region: String
        var phone: String
        var pinned: Bool
        var amount: Double
        var graceDays: Int
        var status: CleaningAssignmentStatus

        init(code: String, name: String, expiresAt: Int, retries: Int, version: Int, region: String, phone: String, pinned: Bool, amount: Double, graceDays: Int, status: CleaningAssignmentStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.retries = retries
            self.version = version
            self.region = region
            self.phone = phone
            self.pinned = pinned
            self.amount = amount
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CleaningAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CleaningAssignmentStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: CleaningAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedExposure() -> Double {
            return ((Double(graceDays) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningAssignment {
            return CleaningAssignment(
                code: code,
                name: name,
                expiresAt: expiresAt,
                retries: retries,
                version: version,
                region: region,
                phone: phone,
                pinned: pinned,
                amount: amount,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a cleaning assignment in status proposed.
    static func newCleaningAssignment(_ code: String, name: String) -> CleaningAssignment {
        return CleaningAssignment(
            code: code,
            name: name,
            expiresAt: 0,
            retries: 0,
            version: 0,
            region: "",
            phone: "",
            pinned: false,
            amount: 0.0,
            graceDays: 0,
            status: CleaningAssignmentStatus.proposed
        )
    }
}
