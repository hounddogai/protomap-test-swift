import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted assessment threshold is in its life cycle.
    enum WeightedAssessmentThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a weighted assessment threshold and its current status.
    final class WeightedAssessmentThreshold {
        var code: String
        var label: String
        var rate: Double
        var specialty: String
        var facility: String
        var ward: String
        var category: String
        var clinicianID: String
        var phone: String
        var status: WeightedAssessmentThresholdStatus

        init(code: String, label: String, rate: Double, specialty: String, facility: String, ward: String, category: String, clinicianID: String, phone: String, status: WeightedAssessmentThresholdStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.specialty = specialty
            self.facility = facility
            self.ward = ward
            self.category = category
            self.clinicianID = clinicianID
            self.phone = phone
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

        func canMoveTo(_ next: WeightedAssessmentThresholdStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedAssessmentThresholdStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WeightedAssessmentThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted assessment threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> WeightedAssessmentThreshold {
            return WeightedAssessmentThreshold(
                code: code,
                label: label,
                rate: rate,
                specialty: specialty,
                facility: facility,
                ward: ward,
                category: category,
                clinicianID: clinicianID,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted assessment threshold in status created.
    static func newWeightedAssessmentThreshold(_ code: String, label: String) -> WeightedAssessmentThreshold {
        return WeightedAssessmentThreshold(
            code: code,
            label: label,
            rate: 0.0,
            specialty: "",
            facility: "",
            ward: "",
            category: "",
            clinicianID: "",
            phone: "",
            status: WeightedAssessmentThresholdStatus.created
        )
    }
}
