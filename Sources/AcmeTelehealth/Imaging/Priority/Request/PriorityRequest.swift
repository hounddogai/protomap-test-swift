import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority request is in its life cycle.
    enum PriorityRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A priority request as the priority team keeps it.
    final class PriorityRequest {
        var code: String
        var name: String
        var budget: Double
        var country: String
        var summary: String
        var discount: Double
        var limit: Int
        var diagnosisCode: String
        var allergy: String
        var status: PriorityRequestStatus

        init(code: String, name: String, budget: Double, country: String, summary: String, discount: Double, limit: Int, diagnosisCode: String, allergy: String, status: PriorityRequestStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.country = country
            self.summary = summary
            self.discount = discount
            self.limit = limit
            self.diagnosisCode = diagnosisCode
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityRequestStatus) -> Bool {
            switch status {
            case .new:
                return next == PriorityRequestStatus.queued || next == PriorityRequestStatus.failed
            case .queued:
                return next == PriorityRequestStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: PriorityRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("priority request") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((discount + budget) * 100).rounded() / 100
        }

        func copyValue() -> PriorityRequest {
            return PriorityRequest(
                code: code,
                name: name,
                budget: budget,
                country: country,
                summary: summary,
                discount: discount,
                limit: limit,
                diagnosisCode: diagnosisCode,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a priority request in status new.
    static func newPriorityRequest(_ code: String, name: String) -> PriorityRequest {
        return PriorityRequest(
            code: code,
            name: name,
            budget: 0.0,
            country: "",
            summary: "",
            discount: 0.0,
            limit: 0,
            diagnosisCode: "",
            allergy: "",
            status: PriorityRequestStatus.new
        )
    }
}
