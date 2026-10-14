import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program draft is in its life cycle.
    enum ProgramDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One program draft, with what the planners need to act on it.
    final class ProgramDraft {
        var code: String
        var title: String
        var archived: Bool
        var phone: String
        var description: String
        var expiresAt: Int
        var checksum: String
        var timezone: String
        var payer: String
        var status: ProgramDraftStatus

        init(code: String, title: String, archived: Bool, phone: String, description: String, expiresAt: Int, checksum: String, timezone: String, payer: String, status: ProgramDraftStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.phone = phone
            self.description = description
            self.expiresAt = expiresAt
            self.checksum = checksum
            self.timezone = timezone
            self.payer = payer
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

        func canMoveTo(_ next: ProgramDraftStatus) -> Bool {
            switch status {
            case .created:
                return next == ProgramDraftStatus.validated || next == ProgramDraftStatus.retired
            case .validated:
                return next == ProgramDraftStatus.published || next == ProgramDraftStatus.retired
            case .published:
                return next == ProgramDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> ProgramDraft {
            return ProgramDraft(
                code: code,
                title: title,
                archived: archived,
                phone: phone,
                description: description,
                expiresAt: expiresAt,
                checksum: checksum,
                timezone: timezone,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a program draft in status created.
    static func newProgramDraft(_ code: String, title: String) -> ProgramDraft {
        return ProgramDraft(
            code: code,
            title: title,
            archived: false,
            phone: "",
            description: "",
            expiresAt: 0,
            checksum: "",
            timezone: "",
            payer: "",
            status: ProgramDraftStatus.created
        )
    }
}
