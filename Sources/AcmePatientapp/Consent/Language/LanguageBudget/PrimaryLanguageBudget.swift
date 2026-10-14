import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary language budget is in its life cycle.
    enum PrimaryLanguageBudgetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A primary language budget as the language team keeps it.
    final class PrimaryLanguageBudget {
        var code: String
        var label: String
        var refills: Int
        var ownerID: String
        var attributes: [String: String]
        var rate: Double
        var allergy: String
        var facility: String
        var specialty: String
        var status: PrimaryLanguageBudgetStatus

        init(code: String, label: String, refills: Int, ownerID: String, attributes: [String: String], rate: Double, allergy: String, facility: String, specialty: String, status: PrimaryLanguageBudgetStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.ownerID = ownerID
            self.attributes = attributes
            self.rate = rate
            self.allergy = allergy
            self.facility = facility
            self.specialty = specialty
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

        func canMoveTo(_ next: PrimaryLanguageBudgetStatus) -> Bool {
            switch status {
            case .planned:
                return next == PrimaryLanguageBudgetStatus.scheduled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == PrimaryLanguageBudgetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryLanguageBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary language budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func effectiveLoad() -> Double {
            return ((Double(refills) + rate) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryLanguageBudget {
            return PrimaryLanguageBudget(
                code: code,
                label: label,
                refills: refills,
                ownerID: ownerID,
                attributes: attributes,
                rate: rate,
                allergy: allergy,
                facility: facility,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a primary language budget in status planned.
    static func newPrimaryLanguageBudget(_ code: String, label: String) -> PrimaryLanguageBudget {
        return PrimaryLanguageBudget(
            code: code,
            label: label,
            refills: 0,
            ownerID: "",
            attributes: [:],
            rate: 0.0,
            allergy: "",
            facility: "",
            specialty: "",
            status: PrimaryLanguageBudgetStatus.planned
        )
    }
}
