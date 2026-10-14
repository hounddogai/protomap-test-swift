import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped skill mix slot is in its life cycle.
    enum CappedSkillMixSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One capped skill mix slot, with what the planners need to act on it.
    final class CappedSkillMixSlot {
        var code: String
        var title: String
        var dosageMg: Double
        var updatedAt: Int
        var weight: Double
        var unit: String
        var status: CappedSkillMixSlotStatus

        init(code: String, title: String, dosageMg: Double, updatedAt: Int, weight: Double, unit: String, status: CappedSkillMixSlotStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.updatedAt = updatedAt
            self.weight = weight
            self.unit = unit
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

        func canMoveTo(_ next: CappedSkillMixSlotStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedSkillMixSlotStatus.active || next == CappedSkillMixSlotStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CappedSkillMixSlotStatus.suspended || next == CappedSkillMixSlotStatus.closed
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

        func moveTo(_ next: CappedSkillMixSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped skill mix slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return ((Double(updatedAt) - weight) * 100).rounded() / 100
        }

        func copyValue() -> CappedSkillMixSlot {
            return CappedSkillMixSlot(
                code: code,
                title: title,
                dosageMg: dosageMg,
                updatedAt: updatedAt,
                weight: weight,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped skill mix slot in status draft.
    static func newCappedSkillMixSlot(_ code: String, title: String) -> CappedSkillMixSlot {
        return CappedSkillMixSlot(
            code: code,
            title: title,
            dosageMg: 0.0,
            updatedAt: 0,
            weight: 0.0,
            unit: "",
            status: CappedSkillMixSlotStatus.draft
        )
    }
}
