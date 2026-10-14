import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan variance is in its life cycle.
    enum DischargePlanVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A discharge plan variance. Its code is unique within a tenant.
    final class DischargePlanVariance {
        var code: String
        var name: String
        var capacity: Int
        var retries: Int
        var cost: Double
        var rate: Double
        var ownerID: String
        var contactEmail: String
        var discount: Double
        var status: DischargePlanVarianceStatus

        init(code: String, name: String, capacity: Int, retries: Int, cost: Double, rate: Double, ownerID: String, contactEmail: String, discount: Double, status: DischargePlanVarianceStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.retries = retries
            self.cost = cost
            self.rate = rate
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.discount = discount
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

        func canMoveTo(_ next: DischargePlanVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: DischargePlanVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedVolume() -> Double {
            return ((discount - cost) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanVariance {
            return DischargePlanVariance(
                code: code,
                name: name,
                capacity: capacity,
                retries: retries,
                cost: cost,
                rate: rate,
                ownerID: ownerID,
                contactEmail: contactEmail,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a discharge plan variance in status open.
    static func newDischargePlanVariance(_ code: String, name: String) -> DischargePlanVariance {
        return DischargePlanVariance(
            code: code,
            name: name,
            capacity: 0,
            retries: 0,
            cost: 0.0,
            rate: 0.0,
            ownerID: "",
            contactEmail: "",
            discount: 0.0,
            status: DischargePlanVarianceStatus.`open`
        )
    }
}
