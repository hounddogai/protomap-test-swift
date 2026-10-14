import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation assignment is in its life cycle.
    enum RevocationAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A revocation assignment as the revocation team keeps it.
    final class RevocationAssignment {
        var code: String
        var name: String
        var copay: Double
        var pinned: Bool
        var facility: String
        var batchSize: Int
        var status: RevocationAssignmentStatus

        init(code: String, name: String, copay: Double, pinned: Bool, facility: String, batchSize: Int, status: RevocationAssignmentStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.pinned = pinned
            self.facility = facility
            self.batchSize = batchSize
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

        func canMoveTo(_ next: RevocationAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RevocationAssignmentStatus.withdrawn
            case .rejected:
                return next == RevocationAssignmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveVolume() -> Double {
            return ((copay + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationAssignment {
            return RevocationAssignment(
                code: code,
                name: name,
                copay: copay,
                pinned: pinned,
                facility: facility,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a revocation assignment in status proposed.
    static func newRevocationAssignment(_ code: String, name: String) -> RevocationAssignment {
        return RevocationAssignment(
            code: code,
            name: name,
            copay: 0.0,
            pinned: false,
            facility: "",
            batchSize: 0,
            status: RevocationAssignmentStatus.proposed
        )
    }
}
