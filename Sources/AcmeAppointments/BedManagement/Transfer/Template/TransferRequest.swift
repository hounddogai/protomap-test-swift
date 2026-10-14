import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer request is in its life cycle.
    enum TransferRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A transfer request as the transfer team keeps it.
    final class TransferRequest {
        var code: String
        var label: String
        var durationMinutes: Int
        var revision: Int
        var encounterID: String
        var summary: String
        var version: Int
        var status: TransferRequestStatus

        init(code: String, label: String, durationMinutes: Int, revision: Int, encounterID: String, summary: String, version: Int, status: TransferRequestStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.revision = revision
            self.encounterID = encounterID
            self.summary = summary
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == TransferRequestStatus.suspended || next == TransferRequestStatus.closed
            case .suspended:
                return next == TransferRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedExposure() -> Double {
            return (Double(version) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> TransferRequest {
            return TransferRequest(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                revision: revision,
                encounterID: encounterID,
                summary: summary,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a transfer request in status draft.
    static func newTransferRequest(_ code: String, label: String) -> TransferRequest {
        return TransferRequest(
            code: code,
            label: label,
            durationMinutes: 0,
            revision: 0,
            encounterID: "",
            summary: "",
            version: 0,
            status: TransferRequestStatus.draft
        )
    }
}
