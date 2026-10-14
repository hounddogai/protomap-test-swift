import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict handoff adjustment is in its life cycle.
    enum StrictHandoffAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict handoff adjustment as the handoff team keeps it.
    final class StrictHandoffAdjustment {
        var code: String
        var name: String
        var ratio: Double
        var unit: String
        var graceDays: Int
        var clinicianID: String
        var maximum: Double
        var externalRef: String
        var category: String
        var region: String
        var status: StrictHandoffAdjustmentStatus

        init(code: String, name: String, ratio: Double, unit: String, graceDays: Int, clinicianID: String, maximum: Double, externalRef: String, category: String, region: String, status: StrictHandoffAdjustmentStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.unit = unit
            self.graceDays = graceDays
            self.clinicianID = clinicianID
            self.maximum = maximum
            self.externalRef = externalRef
            self.category = category
            self.region = region
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

        func canMoveTo(_ next: StrictHandoffAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictHandoffAdjustmentStatus.pending || next == StrictHandoffAdjustmentStatus.closed
            case .pending:
                return next == StrictHandoffAdjustmentStatus.active || next == StrictHandoffAdjustmentStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == StrictHandoffAdjustmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictHandoffAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict handoff adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveTotal() -> Double {
            return ((ratio - maximum) * 100).rounded() / 100
        }

        func copyValue() -> StrictHandoffAdjustment {
            return StrictHandoffAdjustment(
                code: code,
                name: name,
                ratio: ratio,
                unit: unit,
                graceDays: graceDays,
                clinicianID: clinicianID,
                maximum: maximum,
                externalRef: externalRef,
                category: category,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict handoff adjustment in status draft.
    static func newStrictHandoffAdjustment(_ code: String, name: String) -> StrictHandoffAdjustment {
        return StrictHandoffAdjustment(
            code: code,
            name: name,
            ratio: 0.0,
            unit: "",
            graceDays: 0,
            clinicianID: "",
            maximum: 0.0,
            externalRef: "",
            category: "",
            region: "",
            status: StrictHandoffAdjustmentStatus.draft
        )
    }
}
