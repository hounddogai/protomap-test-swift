import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool quota is in its life cycle.
    enum FloatPoolQuotaStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One float pool quota, with what the planners need to act on it.
    final class FloatPoolQuota {
        var code: String
        var label: String
        var batchSize: Int
        var ceiling: Double
        var durationMinutes: Int
        var visible: Bool
        var budget: Double
        var status: FloatPoolQuotaStatus

        init(code: String, label: String, batchSize: Int, ceiling: Double, durationMinutes: Int, visible: Bool, budget: Double, status: FloatPoolQuotaStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.ceiling = ceiling
            self.durationMinutes = durationMinutes
            self.visible = visible
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

        func canMoveTo(_ next: FloatPoolQuotaStatus) -> Bool {
            switch status {
            case .draft:
                return next == FloatPoolQuotaStatus.active || next == FloatPoolQuotaStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FloatPoolQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("float pool quota") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(batchSize) + budget) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolQuota {
            return FloatPoolQuota(
                code: code,
                label: label,
                batchSize: batchSize,
                ceiling: ceiling,
                durationMinutes: durationMinutes,
                visible: visible,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a float pool quota in status draft.
    static func newFloatPoolQuota(_ code: String, label: String) -> FloatPoolQuota {
        return FloatPoolQuota(
            code: code,
            label: label,
            batchSize: 0,
            ceiling: 0.0,
            durationMinutes: 0,
            visible: false,
            budget: 0.0,
            status: FloatPoolQuotaStatus.draft
        )
    }
}
