import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted interaction group is in its life cycle.
    enum WeightedInteractionGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One weighted interaction group, with what the planners need to act on it.
    final class WeightedInteractionGroup {
        var code: String
        var name: String
        var discount: Double
        var batchSize: Int
        var diagnosisCode: String
        var patientRef: String
        var ward: String
        var procedureCode: String
        var status: WeightedInteractionGroupStatus

        init(code: String, name: String, discount: Double, batchSize: Int, diagnosisCode: String, patientRef: String, ward: String, procedureCode: String, status: WeightedInteractionGroupStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.batchSize = batchSize
            self.diagnosisCode = diagnosisCode
            self.patientRef = patientRef
            self.ward = ward
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: WeightedInteractionGroupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WeightedInteractionGroupStatus.inReview || next == WeightedInteractionGroupStatus.archived
            case .inReview:
                return next == WeightedInteractionGroupStatus.resolved || next == WeightedInteractionGroupStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == WeightedInteractionGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedInteractionGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted interaction group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedValue() -> Double {
            return (discount * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> WeightedInteractionGroup {
            return WeightedInteractionGroup(
                code: code,
                name: name,
                discount: discount,
                batchSize: batchSize,
                diagnosisCode: diagnosisCode,
                patientRef: patientRef,
                ward: ward,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a weighted interaction group in status open.
    static func newWeightedInteractionGroup(_ code: String, name: String) -> WeightedInteractionGroup {
        return WeightedInteractionGroup(
            code: code,
            name: name,
            discount: 0.0,
            batchSize: 0,
            diagnosisCode: "",
            patientRef: "",
            ward: "",
            procedureCode: "",
            status: WeightedInteractionGroupStatus.`open`
        )
    }
}
