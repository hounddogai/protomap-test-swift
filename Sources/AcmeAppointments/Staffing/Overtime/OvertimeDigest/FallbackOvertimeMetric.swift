import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback overtime metric is in its life cycle.
    enum FallbackOvertimeMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a fallback overtime metric and its current status.
    final class FallbackOvertimeMetric {
        var code: String
        var name: String
        var currency: String
        var weight: Double
        var quantity: Int
        var clinicianID: String
        var copay: Double
        var active: Bool
        var allergy: String
        var phone: String
        var approved: Bool
        var status: FallbackOvertimeMetricStatus

        init(code: String, name: String, currency: String, weight: Double, quantity: Int, clinicianID: String, copay: Double, active: Bool, allergy: String, phone: String, approved: Bool, status: FallbackOvertimeMetricStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.weight = weight
            self.quantity = quantity
            self.clinicianID = clinicianID
            self.copay = copay
            self.active = active
            self.allergy = allergy
            self.phone = phone
            self.approved = approved
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

        func canMoveTo(_ next: FallbackOvertimeMetricStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
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
                return next == FallbackOvertimeMetricStatus.reopened || next == FallbackOvertimeMetricStatus.archived
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

        func moveTo(_ next: FallbackOvertimeMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback overtime metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedTotal() -> Double {
            return ((copay + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackOvertimeMetric {
            return FallbackOvertimeMetric(
                code: code,
                name: name,
                currency: currency,
                weight: weight,
                quantity: quantity,
                clinicianID: clinicianID,
                copay: copay,
                active: active,
                allergy: allergy,
                phone: phone,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback overtime metric in status open.
    static func newFallbackOvertimeMetric(_ code: String, name: String) -> FallbackOvertimeMetric {
        return FallbackOvertimeMetric(
            code: code,
            name: name,
            currency: "",
            weight: 0.0,
            quantity: 0,
            clinicianID: "",
            copay: 0.0,
            active: false,
            allergy: "",
            phone: "",
            approved: false,
            status: FallbackOvertimeMetricStatus.`open`
        )
    }
}
