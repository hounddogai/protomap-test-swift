import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance variance is in its life cycle.
    enum RemittanceVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a remittance variance and its current status.
    final class RemittanceVariance {
        var code: String
        var name: String
        var graceDays: Int
        var encounterID: String
        var ownerID: String
        var specialty: String
        var quantity: Int
        var status: RemittanceVarianceStatus

        init(code: String, name: String, graceDays: Int, encounterID: String, ownerID: String, specialty: String, quantity: Int, status: RemittanceVarianceStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.specialty = specialty
            self.quantity = quantity
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

        func canMoveTo(_ next: RemittanceVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RemittanceVarianceStatus.reopened
            case .resolved:
                return next == RemittanceVarianceStatus.reopened || next == RemittanceVarianceStatus.archived
            case .reopened:
                return next == RemittanceVarianceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("remittance variance") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(graceDays) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceVariance {
            return RemittanceVariance(
                code: code,
                name: name,
                graceDays: graceDays,
                encounterID: encounterID,
                ownerID: ownerID,
                specialty: specialty,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a remittance variance in status open.
    static func newRemittanceVariance(_ code: String, name: String) -> RemittanceVariance {
        return RemittanceVariance(
            code: code,
            name: name,
            graceDays: 0,
            encounterID: "",
            ownerID: "",
            specialty: "",
            quantity: 0,
            status: RemittanceVarianceStatus.`open`
        )
    }
}
