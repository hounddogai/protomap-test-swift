import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap budget is in its life cycle.
    enum CareGapBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a care gap budget and its current status.
    final class CareGapBudget {
        var code: String
        var name: String
        var visible: Bool
        var category: String
        var phone: String
        var summary: String
        var maximum: Double
        var country: String
        var diagnosisCode: String
        var status: CareGapBudgetStatus

        init(code: String, name: String, visible: Bool, category: String, phone: String, summary: String, maximum: Double, country: String, diagnosisCode: String, status: CareGapBudgetStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.category = category
            self.phone = phone
            self.summary = summary
            self.maximum = maximum
            self.country = country
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: CareGapBudgetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CareGapBudgetStatus.done || next == CareGapBudgetStatus.failed
            case .running:
                return next == CareGapBudgetStatus.done
            case .done:
                return next == CareGapBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care gap budget") \(code)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> CareGapBudget {
            return CareGapBudget(
                code: code,
                name: name,
                visible: visible,
                category: category,
                phone: phone,
                summary: summary,
                maximum: maximum,
                country: country,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a care gap budget in status new.
    static func newCareGapBudget(_ code: String, name: String) -> CareGapBudget {
        return CareGapBudget(
            code: code,
            name: name,
            visible: false,
            category: "",
            phone: "",
            summary: "",
            maximum: 0.0,
            country: "",
            diagnosisCode: "",
            status: CareGapBudgetStatus.new
        )
    }
}
