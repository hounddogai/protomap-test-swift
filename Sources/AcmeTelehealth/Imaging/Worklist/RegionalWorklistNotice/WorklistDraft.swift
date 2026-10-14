import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist draft is in its life cycle.
    enum WorklistDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One worklist draft, with what the planners need to act on it.
    final class WorklistDraft {
        var code: String
        var name: String
        var contactEmail: String
        var endsAt: Int
        var amount: Double
        var patientRef: String
        var timezone: String
        var checksum: String
        var approved: Bool
        var expiresAt: Int
        var status: WorklistDraftStatus

        init(code: String, name: String, contactEmail: String, endsAt: Int, amount: Double, patientRef: String, timezone: String, checksum: String, approved: Bool, expiresAt: Int, status: WorklistDraftStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.endsAt = endsAt
            self.amount = amount
            self.patientRef = patientRef
            self.timezone = timezone
            self.checksum = checksum
            self.approved = approved
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: WorklistDraftStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WorklistDraftStatus.rejected || next == WorklistDraftStatus.withdrawn
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

        func moveTo(_ next: WorklistDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return ((Double(endsAt) + amount) * 100).rounded() / 100
        }

        func copyValue() -> WorklistDraft {
            return WorklistDraft(
                code: code,
                name: name,
                contactEmail: contactEmail,
                endsAt: endsAt,
                amount: amount,
                patientRef: patientRef,
                timezone: timezone,
                checksum: checksum,
                approved: approved,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a worklist draft in status proposed.
    static func newWorklistDraft(_ code: String, name: String) -> WorklistDraft {
        return WorklistDraft(
            code: code,
            name: name,
            contactEmail: "",
            endsAt: 0,
            amount: 0.0,
            patientRef: "",
            timezone: "",
            checksum: "",
            approved: false,
            expiresAt: 0,
            status: WorklistDraftStatus.proposed
        )
    }
}
