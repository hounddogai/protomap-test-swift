import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan quota is in its life cycle.
    enum DischargePlanQuotaStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One discharge plan quota, with what the planners need to act on it.
    final class DischargePlanQuota {
        var code: String
        var label: String
        var source: String
        var title: String
        var description: String
        var active: Bool
        var sequence: Int
        var budget: Double
        var endsAt: Int
        var status: DischargePlanQuotaStatus

        init(code: String, label: String, source: String, title: String, description: String, active: Bool, sequence: Int, budget: Double, endsAt: Int, status: DischargePlanQuotaStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.title = title
            self.description = description
            self.active = active
            self.sequence = sequence
            self.budget = budget
            self.endsAt = endsAt
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

        func canMoveTo(_ next: DischargePlanQuotaStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == DischargePlanQuotaStatus.active
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == DischargePlanQuotaStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return (budget * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanQuota {
            return DischargePlanQuota(
                code: code,
                label: label,
                source: source,
                title: title,
                description: description,
                active: active,
                sequence: sequence,
                budget: budget,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a discharge plan quota in status draft.
    static func newDischargePlanQuota(_ code: String, label: String) -> DischargePlanQuota {
        return DischargePlanQuota(
            code: code,
            label: label,
            source: "",
            title: "",
            description: "",
            active: false,
            sequence: 0,
            budget: 0.0,
            endsAt: 0,
            status: DischargePlanQuotaStatus.draft
        )
    }
}
