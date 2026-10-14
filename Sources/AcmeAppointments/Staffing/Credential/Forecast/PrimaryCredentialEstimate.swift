import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary credential estimate is in its life cycle.
    enum PrimaryCredentialEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a primary credential estimate and its current status.
    final class PrimaryCredentialEstimate {
        var code: String
        var title: String
        var externalRef: String
        var expiresAt: Int
        var sequence: Int
        var rate: Double
        var unit: String
        var quantity: Int
        var status: PrimaryCredentialEstimateStatus

        init(code: String, title: String, externalRef: String, expiresAt: Int, sequence: Int, rate: Double, unit: String, quantity: Int, status: PrimaryCredentialEstimateStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.expiresAt = expiresAt
            self.sequence = sequence
            self.rate = rate
            self.unit = unit
            self.quantity = quantity
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

        func canMoveTo(_ next: PrimaryCredentialEstimateStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryCredentialEstimateStatus.closed
            case .pending:
                return next == PrimaryCredentialEstimateStatus.active || next == PrimaryCredentialEstimateStatus.closed
            case .active:
                return next == PrimaryCredentialEstimateStatus.suspended || next == PrimaryCredentialEstimateStatus.closed
            case .suspended:
                return next == PrimaryCredentialEstimateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCredentialEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary credential estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return ((Double(quantity) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCredentialEstimate {
            return PrimaryCredentialEstimate(
                code: code,
                title: title,
                externalRef: externalRef,
                expiresAt: expiresAt,
                sequence: sequence,
                rate: rate,
                unit: unit,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary credential estimate in status draft.
    static func newPrimaryCredentialEstimate(_ code: String, title: String) -> PrimaryCredentialEstimate {
        return PrimaryCredentialEstimate(
            code: code,
            title: title,
            externalRef: "",
            expiresAt: 0,
            sequence: 0,
            rate: 0.0,
            unit: "",
            quantity: 0,
            status: PrimaryCredentialEstimateStatus.draft
        )
    }
}
