import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending courier assignment is in its life cycle.
    enum PendingCourierAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A pending courier assignment. Its code is unique within a tenant.
    final class PendingCourierAssignment {
        var code: String
        var name: String
        var facility: String
        var maximum: Double
        var procedureCode: String
        var discount: Double
        var contactEmail: String
        var graceDays: Int
        var ratio: Double
        var refills: Int
        var status: PendingCourierAssignmentStatus

        init(code: String, name: String, facility: String, maximum: Double, procedureCode: String, discount: Double, contactEmail: String, graceDays: Int, ratio: Double, refills: Int, status: PendingCourierAssignmentStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.maximum = maximum
            self.procedureCode = procedureCode
            self.discount = discount
            self.contactEmail = contactEmail
            self.graceDays = graceDays
            self.ratio = ratio
            self.refills = refills
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

        func canMoveTo(_ next: PendingCourierAssignmentStatus) -> Bool {
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
                case .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingCourierAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending courier assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending courier assignment") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(refills) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> PendingCourierAssignment {
            return PendingCourierAssignment(
                code: code,
                name: name,
                facility: facility,
                maximum: maximum,
                procedureCode: procedureCode,
                discount: discount,
                contactEmail: contactEmail,
                graceDays: graceDays,
                ratio: ratio,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending courier assignment in status requested.
    static func newPendingCourierAssignment(_ code: String, name: String) -> PendingCourierAssignment {
        return PendingCourierAssignment(
            code: code,
            name: name,
            facility: "",
            maximum: 0.0,
            procedureCode: "",
            discount: 0.0,
            contactEmail: "",
            graceDays: 0,
            ratio: 0.0,
            refills: 0,
            status: PendingCourierAssignmentStatus.requested
        )
    }
}
