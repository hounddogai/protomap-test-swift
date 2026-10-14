import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary closure assignment is in its life cycle.
    enum PrimaryClosureAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a primary closure assignment and its current status.
    final class PrimaryClosureAssignment {
        var code: String
        var title: String
        var phone: String
        var currency: String
        var acuity: Int
        var amount: Double
        var discount: Double
        var batchSize: Int
        var margin: Double
        var status: PrimaryClosureAssignmentStatus

        init(code: String, title: String, phone: String, currency: String, acuity: Int, amount: Double, discount: Double, batchSize: Int, margin: Double, status: PrimaryClosureAssignmentStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.currency = currency
            self.acuity = acuity
            self.amount = amount
            self.discount = discount
            self.batchSize = batchSize
            self.margin = margin
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

        func canMoveTo(_ next: PrimaryClosureAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryClosureAssignmentStatus.granted
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PrimaryClosureAssignmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryClosureAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary closure assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary closure assignment") \(code)"
        }

        func weightedTotal() -> Double {
            return ((discount - margin) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryClosureAssignment {
            return PrimaryClosureAssignment(
                code: code,
                title: title,
                phone: phone,
                currency: currency,
                acuity: acuity,
                amount: amount,
                discount: discount,
                batchSize: batchSize,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary closure assignment in status requested.
    static func newPrimaryClosureAssignment(_ code: String, title: String) -> PrimaryClosureAssignment {
        return PrimaryClosureAssignment(
            code: code,
            title: title,
            phone: "",
            currency: "",
            acuity: 0,
            amount: 0.0,
            discount: 0.0,
            batchSize: 0,
            margin: 0.0,
            status: PrimaryClosureAssignmentStatus.requested
        )
    }
}
