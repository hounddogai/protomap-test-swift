import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form plan is in its life cycle.
    enum ConsentFormPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a consent form plan and its current status.
    final class ConsentFormPlan {
        var code: String
        var name: String
        var currency: String
        var updatedAt: Int
        var floorValue: Double
        var procedureCode: String
        var margin: Double
        var budget: Double
        var weight: Double
        var sequence: Int
        var status: ConsentFormPlanStatus

        init(code: String, name: String, currency: String, updatedAt: Int, floorValue: Double, procedureCode: String, margin: Double, budget: Double, weight: Double, sequence: Int, status: ConsentFormPlanStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.updatedAt = updatedAt
            self.floorValue = floorValue
            self.procedureCode = procedureCode
            self.margin = margin
            self.budget = budget
            self.weight = weight
            self.sequence = sequence
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

        func canMoveTo(_ next: ConsentFormPlanStatus) -> Bool {
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
                return next == ConsentFormPlanStatus.resolved
            case .resolved:
                switch next {
                case .reopened:
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

        func moveTo(_ next: ConsentFormPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netExposure() -> Double {
            return ((Double(sequence) - budget) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormPlan {
            return ConsentFormPlan(
                code: code,
                name: name,
                currency: currency,
                updatedAt: updatedAt,
                floorValue: floorValue,
                procedureCode: procedureCode,
                margin: margin,
                budget: budget,
                weight: weight,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a consent form plan in status open.
    static func newConsentFormPlan(_ code: String, name: String) -> ConsentFormPlan {
        return ConsentFormPlan(
            code: code,
            name: name,
            currency: "",
            updatedAt: 0,
            floorValue: 0.0,
            procedureCode: "",
            margin: 0.0,
            budget: 0.0,
            weight: 0.0,
            sequence: 0,
            status: ConsentFormPlanStatus.`open`
        )
    }
}
