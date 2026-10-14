import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range rollup is in its life cycle.
    enum ReferenceRangeRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a reference range rollup and its current status.
    final class ReferenceRangeRollup {
        var code: String
        var label: String
        var title: String
        var acuity: Int
        var unit: String
        var updatedAt: Int
        var status: ReferenceRangeRollupStatus

        init(code: String, label: String, title: String, acuity: Int, unit: String, updatedAt: Int, status: ReferenceRangeRollupStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.acuity = acuity
            self.unit = unit
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: ReferenceRangeRollupStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ReferenceRangeRollupStatus.active || next == ReferenceRangeRollupStatus.closed
            case .active:
                return next == ReferenceRangeRollupStatus.closed
            case .suspended:
                return next == ReferenceRangeRollupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return (Double(acuity) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeRollup {
            return ReferenceRangeRollup(
                code: code,
                label: label,
                title: title,
                acuity: acuity,
                unit: unit,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a reference range rollup in status draft.
    static func newReferenceRangeRollup(_ code: String, label: String) -> ReferenceRangeRollup {
        return ReferenceRangeRollup(
            code: code,
            label: label,
            title: "",
            acuity: 0,
            unit: "",
            updatedAt: 0,
            status: ReferenceRangeRollupStatus.draft
        )
    }
}
