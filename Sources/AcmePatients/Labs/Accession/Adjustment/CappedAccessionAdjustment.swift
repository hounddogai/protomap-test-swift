import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped accession adjustment is in its life cycle.
    enum CappedAccessionAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a capped accession adjustment and its current status.
    final class CappedAccessionAdjustment {
        var code: String
        var label: String
        var name: String
        var procedureCode: String
        var contactEmail: String
        var limit: Int
        var amount: Double
        var attempts: Int
        var visible: Bool
        var status: CappedAccessionAdjustmentStatus

        init(code: String, label: String, name: String, procedureCode: String, contactEmail: String, limit: Int, amount: Double, attempts: Int, visible: Bool, status: CappedAccessionAdjustmentStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
            self.limit = limit
            self.amount = amount
            self.attempts = attempts
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedAccessionAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == CappedAccessionAdjustmentStatus.completed
            case .scheduled:
                return next == CappedAccessionAdjustmentStatus.inProgress || next == CappedAccessionAdjustmentStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CappedAccessionAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped accession adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return (Double(attempts) * amount * 100).rounded() / 100
        }

        func copyValue() -> CappedAccessionAdjustment {
            return CappedAccessionAdjustment(
                code: code,
                label: label,
                name: name,
                procedureCode: procedureCode,
                contactEmail: contactEmail,
                limit: limit,
                amount: amount,
                attempts: attempts,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped accession adjustment in status planned.
    static func newCappedAccessionAdjustment(_ code: String, label: String) -> CappedAccessionAdjustment {
        return CappedAccessionAdjustment(
            code: code,
            label: label,
            name: "",
            procedureCode: "",
            contactEmail: "",
            limit: 0,
            amount: 0.0,
            attempts: 0,
            visible: false,
            status: CappedAccessionAdjustmentStatus.planned
        )
    }
}
