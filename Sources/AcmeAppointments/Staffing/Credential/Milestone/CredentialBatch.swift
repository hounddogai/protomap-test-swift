import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential batch is in its life cycle.
    enum CredentialBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One credential batch, with what the planners need to act on it.
    final class CredentialBatch {
        var code: String
        var title: String
        var ward: String
        var budget: Double
        var ownerID: String
        var floorValue: Double
        var status: CredentialBatchStatus

        init(code: String, title: String, ward: String, budget: Double, ownerID: String, floorValue: Double, status: CredentialBatchStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.budget = budget
            self.ownerID = ownerID
            self.floorValue = floorValue
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

        func canMoveTo(_ next: CredentialBatchStatus) -> Bool {
            switch status {
            case .draft:
                return next == CredentialBatchStatus.active
            case .pending:
                return next == CredentialBatchStatus.active || next == CredentialBatchStatus.suspended
            case .active:
                return next == CredentialBatchStatus.suspended || next == CredentialBatchStatus.closed
            case .suspended:
                return next == CredentialBatchStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveLoad() -> Double {
            return ((floorValue - budget) * 100).rounded() / 100
        }

        func copyValue() -> CredentialBatch {
            return CredentialBatch(
                code: code,
                title: title,
                ward: ward,
                budget: budget,
                ownerID: ownerID,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a credential batch in status draft.
    static func newCredentialBatch(_ code: String, title: String) -> CredentialBatch {
        return CredentialBatch(
            code: code,
            title: title,
            ward: "",
            budget: 0.0,
            ownerID: "",
            floorValue: 0.0,
            status: CredentialBatchStatus.draft
        )
    }
}
