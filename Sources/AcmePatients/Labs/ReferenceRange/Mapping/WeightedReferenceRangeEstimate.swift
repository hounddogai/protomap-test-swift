import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted reference range estimate is in its life cycle.
    enum WeightedReferenceRangeEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted reference range estimate. Its code is unique within a tenant.
    final class WeightedReferenceRangeEstimate {
        var code: String
        var name: String
        var title: String
        var archived: Bool
        var durationMinutes: Int
        var unit: String
        var discount: Double
        var maximum: Double
        var phone: String
        var procedureCode: String
        var locale: String
        var status: WeightedReferenceRangeEstimateStatus

        init(code: String, name: String, title: String, archived: Bool, durationMinutes: Int, unit: String, discount: Double, maximum: Double, phone: String, procedureCode: String, locale: String, status: WeightedReferenceRangeEstimateStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.unit = unit
            self.discount = discount
            self.maximum = maximum
            self.phone = phone
            self.procedureCode = procedureCode
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedReferenceRangeEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WeightedReferenceRangeEstimateStatus.rejected
            case .approved:
                return next == WeightedReferenceRangeEstimateStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: WeightedReferenceRangeEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted reference range estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netVolume() -> Double {
            return ((Double(durationMinutes) - discount) * 100).rounded() / 100
        }

        func copyValue() -> WeightedReferenceRangeEstimate {
            return WeightedReferenceRangeEstimate(
                code: code,
                name: name,
                title: title,
                archived: archived,
                durationMinutes: durationMinutes,
                unit: unit,
                discount: discount,
                maximum: maximum,
                phone: phone,
                procedureCode: procedureCode,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted reference range estimate in status proposed.
    static func newWeightedReferenceRangeEstimate(_ code: String, name: String) -> WeightedReferenceRangeEstimate {
        return WeightedReferenceRangeEstimate(
            code: code,
            name: name,
            title: "",
            archived: false,
            durationMinutes: 0,
            unit: "",
            discount: 0.0,
            maximum: 0.0,
            phone: "",
            procedureCode: "",
            locale: "",
            status: WeightedReferenceRangeEstimateStatus.proposed
        )
    }
}
