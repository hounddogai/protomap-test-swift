import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual cleaning assignment is in its life cycle.
    enum ManualCleaningAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual cleaning assignment. Its code is unique within a tenant.
    final class ManualCleaningAssignment {
        var code: String
        var title: String
        var contactEmail: String
        var acuity: Int
        var windowDays: Int
        var margin: Double
        var approved: Bool
        var batchSize: Int
        var copay: Double
        var retries: Int
        var limit: Int
        var status: ManualCleaningAssignmentStatus

        init(code: String, title: String, contactEmail: String, acuity: Int, windowDays: Int, margin: Double, approved: Bool, batchSize: Int, copay: Double, retries: Int, limit: Int, status: ManualCleaningAssignmentStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.acuity = acuity
            self.windowDays = windowDays
            self.margin = margin
            self.approved = approved
            self.batchSize = batchSize
            self.copay = copay
            self.retries = retries
            self.limit = limit
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

        func canMoveTo(_ next: ManualCleaningAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ManualCleaningAssignmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCleaningAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual cleaning assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netValue() -> Double {
            return ((Double(acuity) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ManualCleaningAssignment {
            return ManualCleaningAssignment(
                code: code,
                title: title,
                contactEmail: contactEmail,
                acuity: acuity,
                windowDays: windowDays,
                margin: margin,
                approved: approved,
                batchSize: batchSize,
                copay: copay,
                retries: retries,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual cleaning assignment in status requested.
    static func newManualCleaningAssignment(_ code: String, title: String) -> ManualCleaningAssignment {
        return ManualCleaningAssignment(
            code: code,
            title: title,
            contactEmail: "",
            acuity: 0,
            windowDays: 0,
            margin: 0.0,
            approved: false,
            batchSize: 0,
            copay: 0.0,
            retries: 0,
            limit: 0,
            status: ManualCleaningAssignmentStatus.requested
        )
    }
}
