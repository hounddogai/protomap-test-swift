import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional assessment estimate is in its life cycle.
    enum RegionalAssessmentEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One regional assessment estimate, with what the planners need to act on it.
    final class RegionalAssessmentEstimate {
        var code: String
        var name: String
        var timezone: String
        var externalRef: String
        var clinicianID: String
        var attributes: [String: String]
        var acuity: Int
        var minimum: Double
        var specialty: String
        var ward: String
        var budget: Double
        var status: RegionalAssessmentEstimateStatus

        init(code: String, name: String, timezone: String, externalRef: String, clinicianID: String, attributes: [String: String], acuity: Int, minimum: Double, specialty: String, ward: String, budget: Double, status: RegionalAssessmentEstimateStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.attributes = attributes
            self.acuity = acuity
            self.minimum = minimum
            self.specialty = specialty
            self.ward = ward
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalAssessmentEstimateStatus) -> Bool {
            switch status {
            case .idle:
                return next == RegionalAssessmentEstimateStatus.warming
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RegionalAssessmentEstimateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAssessmentEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional assessment estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional assessment estimate") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedVolume() -> Double {
            return ((minimum - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAssessmentEstimate {
            return RegionalAssessmentEstimate(
                code: code,
                name: name,
                timezone: timezone,
                externalRef: externalRef,
                clinicianID: clinicianID,
                attributes: attributes,
                acuity: acuity,
                minimum: minimum,
                specialty: specialty,
                ward: ward,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional assessment estimate in status idle.
    static func newRegionalAssessmentEstimate(_ code: String, name: String) -> RegionalAssessmentEstimate {
        return RegionalAssessmentEstimate(
            code: code,
            name: name,
            timezone: "",
            externalRef: "",
            clinicianID: "",
            attributes: [:],
            acuity: 0,
            minimum: 0.0,
            specialty: "",
            ward: "",
            budget: 0.0,
            status: RegionalAssessmentEstimateStatus.idle
        )
    }
}
