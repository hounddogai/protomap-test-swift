import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge estimate is in its life cycle.
    enum ChargeEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A charge estimate. Its code is unique within a tenant.
    final class ChargeEstimate {
        var code: String
        var name: String
        var rate: Double
        var expiresAt: Int
        var priority: Int
        var patientRef: String
        var quantity: Int
        var startsAt: Int
        var copay: Double
        var limit: Int
        var status: ChargeEstimateStatus

        init(code: String, name: String, rate: Double, expiresAt: Int, priority: Int, patientRef: String, quantity: Int, startsAt: Int, copay: Double, limit: Int, status: ChargeEstimateStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.expiresAt = expiresAt
            self.priority = priority
            self.patientRef = patientRef
            self.quantity = quantity
            self.startsAt = startsAt
            self.copay = copay
            self.limit = limit
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

        func canMoveTo(_ next: ChargeEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ChargeEstimateStatus.inReview || next == ChargeEstimateStatus.archived
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ChargeEstimateStatus.reopened || next == ChargeEstimateStatus.archived
            case .reopened:
                return next == ChargeEstimateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return ((Double(quantity) - rate) * 100).rounded() / 100
        }

        func copyValue() -> ChargeEstimate {
            return ChargeEstimate(
                code: code,
                name: name,
                rate: rate,
                expiresAt: expiresAt,
                priority: priority,
                patientRef: patientRef,
                quantity: quantity,
                startsAt: startsAt,
                copay: copay,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a charge estimate in status open.
    static func newChargeEstimate(_ code: String, name: String) -> ChargeEstimate {
        return ChargeEstimate(
            code: code,
            name: name,
            rate: 0.0,
            expiresAt: 0,
            priority: 0,
            patientRef: "",
            quantity: 0,
            startsAt: 0,
            copay: 0.0,
            limit: 0,
            status: ChargeEstimateStatus.`open`
        )
    }
}
