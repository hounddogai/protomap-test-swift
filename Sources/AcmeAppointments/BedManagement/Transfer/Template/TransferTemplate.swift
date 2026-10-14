import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer template is in its life cycle.
    enum TransferTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A transfer template. Its code is unique within a tenant.
    final class TransferTemplate {
        var code: String
        var title: String
        var attempts: Int
        var durationMinutes: Int
        var expiresAt: Int
        var clinicianID: String
        var source: String
        var notes: String
        var externalRef: String
        var endsAt: Int
        var status: TransferTemplateStatus

        init(code: String, title: String, attempts: Int, durationMinutes: Int, expiresAt: Int, clinicianID: String, source: String, notes: String, externalRef: String, endsAt: Int, status: TransferTemplateStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.clinicianID = clinicianID
            self.source = source
            self.notes = notes
            self.externalRef = externalRef
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == TransferTemplateStatus.reopened || next == TransferTemplateStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: TransferTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("transfer template") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(expiresAt) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TransferTemplate {
            return TransferTemplate(
                code: code,
                title: title,
                attempts: attempts,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                clinicianID: clinicianID,
                source: source,
                notes: notes,
                externalRef: externalRef,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a transfer template in status open.
    static func newTransferTemplate(_ code: String, title: String) -> TransferTemplate {
        return TransferTemplate(
            code: code,
            title: title,
            attempts: 0,
            durationMinutes: 0,
            expiresAt: 0,
            clinicianID: "",
            source: "",
            notes: "",
            externalRef: "",
            endsAt: 0,
            status: TransferTemplateStatus.`open`
        )
    }
}
