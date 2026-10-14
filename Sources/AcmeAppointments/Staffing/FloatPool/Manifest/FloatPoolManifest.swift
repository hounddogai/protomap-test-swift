import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool manifest is in its life cycle.
    enum FloatPoolManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One float pool manifest, with what the planners need to act on it.
    final class FloatPoolManifest {
        var code: String
        var label: String
        var allergy: String
        var rate: Double
        var clinicianID: String
        var facility: String
        var budget: Double
        var status: FloatPoolManifestStatus

        init(code: String, label: String, allergy: String, rate: Double, clinicianID: String, facility: String, budget: Double, status: FloatPoolManifestStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.rate = rate
            self.clinicianID = clinicianID
            self.facility = facility
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FloatPoolManifestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == FloatPoolManifestStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: FloatPoolManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveTotal() -> Double {
            return (rate * budget * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolManifest {
            return FloatPoolManifest(
                code: code,
                label: label,
                allergy: allergy,
                rate: rate,
                clinicianID: clinicianID,
                facility: facility,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a float pool manifest in status draft.
    static func newFloatPoolManifest(_ code: String, label: String) -> FloatPoolManifest {
        return FloatPoolManifest(
            code: code,
            label: label,
            allergy: "",
            rate: 0.0,
            clinicianID: "",
            facility: "",
            budget: 0.0,
            status: FloatPoolManifestStatus.draft
        )
    }
}
