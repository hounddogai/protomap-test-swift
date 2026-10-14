import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution estimate is in its life cycle.
    enum SubstitutionEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A substitution estimate. Its code is unique within a tenant.
    final class SubstitutionEstimate {
        var code: String
        var name: String
        var facility: String
        var visitMinutes: Int
        var payer: String
        var amount: Double
        var rate: Double
        var discount: Double
        var acuity: Int
        var status: SubstitutionEstimateStatus

        init(code: String, name: String, facility: String, visitMinutes: Int, payer: String, amount: Double, rate: Double, discount: Double, acuity: Int, status: SubstitutionEstimateStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.visitMinutes = visitMinutes
            self.payer = payer
            self.amount = amount
            self.rate = rate
            self.discount = discount
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SubstitutionEstimateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == SubstitutionEstimateStatus.draining || next == SubstitutionEstimateStatus.stopped
            case .draining:
                return next == SubstitutionEstimateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return ((Double(visitMinutes) - rate) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionEstimate {
            return SubstitutionEstimate(
                code: code,
                name: name,
                facility: facility,
                visitMinutes: visitMinutes,
                payer: payer,
                amount: amount,
                rate: rate,
                discount: discount,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a substitution estimate in status idle.
    static func newSubstitutionEstimate(_ code: String, name: String) -> SubstitutionEstimate {
        return SubstitutionEstimate(
            code: code,
            name: name,
            facility: "",
            visitMinutes: 0,
            payer: "",
            amount: 0.0,
            rate: 0.0,
            discount: 0.0,
            acuity: 0,
            status: SubstitutionEstimateStatus.idle
        )
    }
}
