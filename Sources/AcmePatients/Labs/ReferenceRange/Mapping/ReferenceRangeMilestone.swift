import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range milestone is in its life cycle.
    enum ReferenceRangeMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One reference range milestone, with what the planners need to act on it.
    final class ReferenceRangeMilestone {
        var code: String
        var label: String
        var dosageMg: Double
        var unit: String
        var margin: Double
        var category: String
        var status: ReferenceRangeMilestoneStatus

        init(code: String, label: String, dosageMg: Double, unit: String, margin: Double, category: String, status: ReferenceRangeMilestoneStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.unit = unit
            self.margin = margin
            self.category = category
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

        func canMoveTo(_ next: ReferenceRangeMilestoneStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ReferenceRangeMilestoneStatus.published || next == ReferenceRangeMilestoneStatus.retired
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

        func moveTo(_ next: ReferenceRangeMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveTotal() -> Double {
            return ((dosageMg + margin) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeMilestone {
            return ReferenceRangeMilestone(
                code: code,
                label: label,
                dosageMg: dosageMg,
                unit: unit,
                margin: margin,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a reference range milestone in status created.
    static func newReferenceRangeMilestone(_ code: String, label: String) -> ReferenceRangeMilestone {
        return ReferenceRangeMilestone(
            code: code,
            label: label,
            dosageMg: 0.0,
            unit: "",
            margin: 0.0,
            category: "",
            status: ReferenceRangeMilestoneStatus.created
        )
    }
}
