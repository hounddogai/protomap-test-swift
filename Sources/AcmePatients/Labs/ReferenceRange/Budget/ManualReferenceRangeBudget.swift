import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual reference range budget is in its life cycle.
    enum ManualReferenceRangeBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual reference range budget. Its code is unique within a tenant.
    final class ManualReferenceRangeBudget {
        var code: String
        var name: String
        var patientRef: String
        var version: Int
        var threshold: Double
        var allergy: String
        var active: Bool
        var capacity: Int
        var durationMinutes: Int
        var dosageMg: Double
        var status: ManualReferenceRangeBudgetStatus

        init(code: String, name: String, patientRef: String, version: Int, threshold: Double, allergy: String, active: Bool, capacity: Int, durationMinutes: Int, dosageMg: Double, status: ManualReferenceRangeBudgetStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.version = version
            self.threshold = threshold
            self.allergy = allergy
            self.active = active
            self.capacity = capacity
            self.durationMinutes = durationMinutes
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ManualReferenceRangeBudgetStatus) -> Bool {
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
                return next == ManualReferenceRangeBudgetStatus.active || next == ManualReferenceRangeBudgetStatus.closed
            case .active:
                return next == ManualReferenceRangeBudgetStatus.suspended
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

        func moveTo(_ next: ManualReferenceRangeBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual reference range budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedExposure() -> Double {
            return ((Double(durationMinutes) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ManualReferenceRangeBudget {
            return ManualReferenceRangeBudget(
                code: code,
                name: name,
                patientRef: patientRef,
                version: version,
                threshold: threshold,
                allergy: allergy,
                active: active,
                capacity: capacity,
                durationMinutes: durationMinutes,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual reference range budget in status draft.
    static func newManualReferenceRangeBudget(_ code: String, name: String) -> ManualReferenceRangeBudget {
        return ManualReferenceRangeBudget(
            code: code,
            name: name,
            patientRef: "",
            version: 0,
            threshold: 0.0,
            allergy: "",
            active: false,
            capacity: 0,
            durationMinutes: 0,
            dosageMg: 0.0,
            status: ManualReferenceRangeBudgetStatus.draft
        )
    }
}
