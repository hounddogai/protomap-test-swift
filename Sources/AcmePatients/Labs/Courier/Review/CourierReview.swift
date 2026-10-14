import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier review is in its life cycle.
    enum CourierReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A courier review as the courier team keeps it.
    final class CourierReview {
        var code: String
        var name: String
        var minimum: Double
        var weight: Double
        var unit: String
        var discount: Double
        var title: String
        var checksum: String
        var allergy: String
        var patientRef: String
        var status: CourierReviewStatus

        init(code: String, name: String, minimum: Double, weight: Double, unit: String, discount: Double, title: String, checksum: String, allergy: String, patientRef: String, status: CourierReviewStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.weight = weight
            self.unit = unit
            self.discount = discount
            self.title = title
            self.checksum = checksum
            self.allergy = allergy
            self.patientRef = patientRef
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

        func canMoveTo(_ next: CourierReviewStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CourierReviewStatus.resolved || next == CourierReviewStatus.reopened
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: CourierReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return ((minimum + weight) * 100).rounded() / 100
        }

        func copyValue() -> CourierReview {
            return CourierReview(
                code: code,
                name: name,
                minimum: minimum,
                weight: weight,
                unit: unit,
                discount: discount,
                title: title,
                checksum: checksum,
                allergy: allergy,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a courier review in status open.
    static func newCourierReview(_ code: String, name: String) -> CourierReview {
        return CourierReview(
            code: code,
            name: name,
            minimum: 0.0,
            weight: 0.0,
            unit: "",
            discount: 0.0,
            title: "",
            checksum: "",
            allergy: "",
            patientRef: "",
            status: CourierReviewStatus.`open`
        )
    }
}
