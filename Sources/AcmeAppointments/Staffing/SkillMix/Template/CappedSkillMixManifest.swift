import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped skill mix manifest is in its life cycle.
    enum CappedSkillMixManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A capped skill mix manifest. Its code is unique within a tenant.
    final class CappedSkillMixManifest {
        var code: String
        var label: String
        var summary: String
        var quantity: Int
        var cost: Double
        var dosageMg: Double
        var source: String
        var budget: Double
        var phone: String
        var clinicianID: String
        var notes: String
        var status: CappedSkillMixManifestStatus

        init(code: String, label: String, summary: String, quantity: Int, cost: Double, dosageMg: Double, source: String, budget: Double, phone: String, clinicianID: String, notes: String, status: CappedSkillMixManifestStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.quantity = quantity
            self.cost = cost
            self.dosageMg = dosageMg
            self.source = source
            self.budget = budget
            self.phone = phone
            self.clinicianID = clinicianID
            self.notes = notes
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

        func canMoveTo(_ next: CappedSkillMixManifestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CappedSkillMixManifestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedSkillMixManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped skill mix manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedTotal() -> Double {
            return ((budget - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> CappedSkillMixManifest {
            return CappedSkillMixManifest(
                code: code,
                label: label,
                summary: summary,
                quantity: quantity,
                cost: cost,
                dosageMg: dosageMg,
                source: source,
                budget: budget,
                phone: phone,
                clinicianID: clinicianID,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a capped skill mix manifest in status draft.
    static func newCappedSkillMixManifest(_ code: String, label: String) -> CappedSkillMixManifest {
        return CappedSkillMixManifest(
            code: code,
            label: label,
            summary: "",
            quantity: 0,
            cost: 0.0,
            dosageMg: 0.0,
            source: "",
            budget: 0.0,
            phone: "",
            clinicianID: "",
            notes: "",
            status: CappedSkillMixManifestStatus.draft
        )
    }
}
