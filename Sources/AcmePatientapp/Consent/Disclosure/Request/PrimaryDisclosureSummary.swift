import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary disclosure summary is in its life cycle.
    enum PrimaryDisclosureSummaryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A primary disclosure summary as the disclosure team keeps it.
    final class PrimaryDisclosureSummary {
        var code: String
        var name: String
        var quantity: Int
        var patientRef: String
        var region: String
        var currency: String
        var copay: Double
        var weight: Double
        var discount: Double
        var startsAt: Int
        var acuity: Int
        var status: PrimaryDisclosureSummaryStatus

        init(code: String, name: String, quantity: Int, patientRef: String, region: String, currency: String, copay: Double, weight: Double, discount: Double, startsAt: Int, acuity: Int, status: PrimaryDisclosureSummaryStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.patientRef = patientRef
            self.region = region
            self.currency = currency
            self.copay = copay
            self.weight = weight
            self.discount = discount
            self.startsAt = startsAt
            self.acuity = acuity
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

        func canMoveTo(_ next: PrimaryDisclosureSummaryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimaryDisclosureSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary disclosure summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netVolume() -> Double {
            return ((Double(startsAt) - weight) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDisclosureSummary {
            return PrimaryDisclosureSummary(
                code: code,
                name: name,
                quantity: quantity,
                patientRef: patientRef,
                region: region,
                currency: currency,
                copay: copay,
                weight: weight,
                discount: discount,
                startsAt: startsAt,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a primary disclosure summary in status planned.
    static func newPrimaryDisclosureSummary(_ code: String, name: String) -> PrimaryDisclosureSummary {
        return PrimaryDisclosureSummary(
            code: code,
            name: name,
            quantity: 0,
            patientRef: "",
            region: "",
            currency: "",
            copay: 0.0,
            weight: 0.0,
            discount: 0.0,
            startsAt: 0,
            acuity: 0,
            status: PrimaryDisclosureSummaryStatus.planned
        )
    }
}
