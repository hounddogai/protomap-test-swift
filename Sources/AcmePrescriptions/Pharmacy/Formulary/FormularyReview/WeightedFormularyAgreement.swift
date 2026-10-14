import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted formulary agreement is in its life cycle.
    enum WeightedFormularyAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One weighted formulary agreement, with what the planners need to act on it.
    final class WeightedFormularyAgreement {
        var code: String
        var label: String
        var refills: Int
        var durationMinutes: Int
        var priority: Int
        var specialty: String
        var encounterID: String
        var status: WeightedFormularyAgreementStatus

        init(code: String, label: String, refills: Int, durationMinutes: Int, priority: Int, specialty: String, encounterID: String, status: WeightedFormularyAgreementStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.durationMinutes = durationMinutes
            self.priority = priority
            self.specialty = specialty
            self.encounterID = encounterID
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

        func canMoveTo(_ next: WeightedFormularyAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: WeightedFormularyAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted formulary agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(priority) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedFormularyAgreement {
            return WeightedFormularyAgreement(
                code: code,
                label: label,
                refills: refills,
                durationMinutes: durationMinutes,
                priority: priority,
                specialty: specialty,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted formulary agreement in status open.
    static func newWeightedFormularyAgreement(_ code: String, label: String) -> WeightedFormularyAgreement {
        return WeightedFormularyAgreement(
            code: code,
            label: label,
            refills: 0,
            durationMinutes: 0,
            priority: 0,
            specialty: "",
            encounterID: "",
            status: WeightedFormularyAgreementStatus.`open`
        )
    }
}
