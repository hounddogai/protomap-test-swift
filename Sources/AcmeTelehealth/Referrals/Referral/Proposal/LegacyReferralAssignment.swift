import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy referral assignment is in its life cycle.
    enum LegacyReferralAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A legacy referral assignment. Its code is unique within a tenant.
    final class LegacyReferralAssignment {
        var code: String
        var name: String
        var capacity: Int
        var sequence: Int
        var visitMinutes: Int
        var contactEmail: String
        var status: LegacyReferralAssignmentStatus

        init(code: String, name: String, capacity: Int, sequence: Int, visitMinutes: Int, contactEmail: String, status: LegacyReferralAssignmentStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.sequence = sequence
            self.visitMinutes = visitMinutes
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyReferralAssignmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LegacyReferralAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy referral assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedLoad() -> Double {
            return ((Double(visitMinutes) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyReferralAssignment {
            return LegacyReferralAssignment(
                code: code,
                name: name,
                capacity: capacity,
                sequence: sequence,
                visitMinutes: visitMinutes,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy referral assignment in status created.
    static func newLegacyReferralAssignment(_ code: String, name: String) -> LegacyReferralAssignment {
        return LegacyReferralAssignment(
            code: code,
            name: name,
            capacity: 0,
            sequence: 0,
            visitMinutes: 0,
            contactEmail: "",
            status: LegacyReferralAssignmentStatus.created
        )
    }
}
