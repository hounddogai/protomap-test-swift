import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan baseline is in its life cycle.
    enum AcuityPlanBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A acuity plan baseline as the acuity plan team keeps it.
    final class AcuityPlanBaseline {
        var code: String
        var title: String
        var summary: String
        var currency: String
        var quantity: Int
        var country: String
        var description: String
        var retries: Int
        var capacity: Int
        var rate: Double
        var reviewer: String
        var status: AcuityPlanBaselineStatus

        init(code: String, title: String, summary: String, currency: String, quantity: Int, country: String, description: String, retries: Int, capacity: Int, rate: Double, reviewer: String, status: AcuityPlanBaselineStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.currency = currency
            self.quantity = quantity
            self.country = country
            self.description = description
            self.retries = retries
            self.capacity = capacity
            self.rate = rate
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AcuityPlanBaselineStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AcuityPlanBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netTotal() -> Double {
            return ((Double(capacity) + rate) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanBaseline {
            return AcuityPlanBaseline(
                code: code,
                title: title,
                summary: summary,
                currency: currency,
                quantity: quantity,
                country: country,
                description: description,
                retries: retries,
                capacity: capacity,
                rate: rate,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a acuity plan baseline in status created.
    static func newAcuityPlanBaseline(_ code: String, title: String) -> AcuityPlanBaseline {
        return AcuityPlanBaseline(
            code: code,
            title: title,
            summary: "",
            currency: "",
            quantity: 0,
            country: "",
            description: "",
            retries: 0,
            capacity: 0,
            rate: 0.0,
            reviewer: "",
            status: AcuityPlanBaselineStatus.created
        )
    }
}
