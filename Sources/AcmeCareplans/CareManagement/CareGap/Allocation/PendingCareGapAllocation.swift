import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending care gap allocation is in its life cycle.
    enum PendingCareGapAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending care gap allocation as the care gap team keeps it.
    final class PendingCareGapAllocation {
        var code: String
        var title: String
        var procedureCode: String
        var bed: String
        var endsAt: Int
        var maximum: Double
        var discount: Double
        var dosageMg: Double
        var status: PendingCareGapAllocationStatus

        init(code: String, title: String, procedureCode: String, bed: String, endsAt: Int, maximum: Double, discount: Double, dosageMg: Double, status: PendingCareGapAllocationStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.bed = bed
            self.endsAt = endsAt
            self.maximum = maximum
            self.discount = discount
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

        func canMoveTo(_ next: PendingCareGapAllocationStatus) -> Bool {
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
                return next == PendingCareGapAllocationStatus.active || next == PendingCareGapAllocationStatus.suspended
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == PendingCareGapAllocationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCareGapAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending care gap allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending care gap allocation") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(endsAt) * discount * 100).rounded() / 100
        }

        func copyValue() -> PendingCareGapAllocation {
            return PendingCareGapAllocation(
                code: code,
                title: title,
                procedureCode: procedureCode,
                bed: bed,
                endsAt: endsAt,
                maximum: maximum,
                discount: discount,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending care gap allocation in status draft.
    static func newPendingCareGapAllocation(_ code: String, title: String) -> PendingCareGapAllocation {
        return PendingCareGapAllocation(
            code: code,
            title: title,
            procedureCode: "",
            bed: "",
            endsAt: 0,
            maximum: 0.0,
            discount: 0.0,
            dosageMg: 0.0,
            status: PendingCareGapAllocationStatus.draft
        )
    }
}
