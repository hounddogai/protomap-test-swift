import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual remittance snapshot is in its life cycle.
    enum ManualRemittanceSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual remittance snapshot. Its code is unique within a tenant.
    final class ManualRemittanceSnapshot {
        var code: String
        var name: String
        var attempts: Int
        var amount: Double
        var quantity: Int
        var country: String
        var acuity: Int
        var minimum: Double
        var status: ManualRemittanceSnapshotStatus

        init(code: String, name: String, attempts: Int, amount: Double, quantity: Int, country: String, acuity: Int, minimum: Double, status: ManualRemittanceSnapshotStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.amount = amount
            self.quantity = quantity
            self.country = country
            self.acuity = acuity
            self.minimum = minimum
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

        func canMoveTo(_ next: ManualRemittanceSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
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
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualRemittanceSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual remittance snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual remittance snapshot") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(attempts) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ManualRemittanceSnapshot {
            return ManualRemittanceSnapshot(
                code: code,
                name: name,
                attempts: attempts,
                amount: amount,
                quantity: quantity,
                country: country,
                acuity: acuity,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual remittance snapshot in status open.
    static func newManualRemittanceSnapshot(_ code: String, name: String) -> ManualRemittanceSnapshot {
        return ManualRemittanceSnapshot(
            code: code,
            name: name,
            attempts: 0,
            amount: 0.0,
            quantity: 0,
            country: "",
            acuity: 0,
            minimum: 0.0,
            status: ManualRemittanceSnapshotStatus.`open`
        )
    }
}
