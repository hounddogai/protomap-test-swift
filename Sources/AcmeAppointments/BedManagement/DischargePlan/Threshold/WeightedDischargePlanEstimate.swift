import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted discharge plan estimate is in its life cycle.
    enum WeightedDischargePlanEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One weighted discharge plan estimate, with what the planners need to act on it.
    final class WeightedDischargePlanEstimate {
        var code: String
        var label: String
        var clinicianID: String
        var minimum: Double
        var contactEmail: String
        var updatedAt: Int
        var country: String
        var budget: Double
        var segment: String
        var locale: String
        var status: WeightedDischargePlanEstimateStatus

        init(code: String, label: String, clinicianID: String, minimum: Double, contactEmail: String, updatedAt: Int, country: String, budget: Double, segment: String, locale: String, status: WeightedDischargePlanEstimateStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.minimum = minimum
            self.contactEmail = contactEmail
            self.updatedAt = updatedAt
            self.country = country
            self.budget = budget
            self.segment = segment
            self.locale = locale
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

        func canMoveTo(_ next: WeightedDischargePlanEstimateStatus) -> Bool {
            switch status {
            case .planned:
                return next == WeightedDischargePlanEstimateStatus.scheduled || next == WeightedDischargePlanEstimateStatus.cancelled
            case .scheduled:
                return next == WeightedDischargePlanEstimateStatus.inProgress || next == WeightedDischargePlanEstimateStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == WeightedDischargePlanEstimateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedDischargePlanEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted discharge plan estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return ((minimum - budget) * 100).rounded() / 100
        }

        func copyValue() -> WeightedDischargePlanEstimate {
            return WeightedDischargePlanEstimate(
                code: code,
                label: label,
                clinicianID: clinicianID,
                minimum: minimum,
                contactEmail: contactEmail,
                updatedAt: updatedAt,
                country: country,
                budget: budget,
                segment: segment,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted discharge plan estimate in status planned.
    static func newWeightedDischargePlanEstimate(_ code: String, label: String) -> WeightedDischargePlanEstimate {
        return WeightedDischargePlanEstimate(
            code: code,
            label: label,
            clinicianID: "",
            minimum: 0.0,
            contactEmail: "",
            updatedAt: 0,
            country: "",
            budget: 0.0,
            segment: "",
            locale: "",
            status: WeightedDischargePlanEstimateStatus.planned
        )
    }
}
