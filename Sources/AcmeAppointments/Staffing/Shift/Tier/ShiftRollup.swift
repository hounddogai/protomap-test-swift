import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift rollup is in its life cycle.
    enum ShiftRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A shift rollup as the shift team keeps it.
    final class ShiftRollup {
        var code: String
        var label: String
        var minimum: Double
        var ownerID: String
        var clinicianID: String
        var locale: String
        var threshold: Double
        var segment: String
        var status: ShiftRollupStatus

        init(code: String, label: String, minimum: Double, ownerID: String, clinicianID: String, locale: String, threshold: Double, segment: String, status: ShiftRollupStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.ownerID = ownerID
            self.clinicianID = clinicianID
            self.locale = locale
            self.threshold = threshold
            self.segment = segment
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

        func canMoveTo(_ next: ShiftRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == ShiftRollupStatus.closed
            case .pending:
                return next == ShiftRollupStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ShiftRollupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("shift rollup") \(code)"
        }

        func weightedVolume() -> Double {
            return (threshold * minimum * 100).rounded() / 100
        }

        func copyValue() -> ShiftRollup {
            return ShiftRollup(
                code: code,
                label: label,
                minimum: minimum,
                ownerID: ownerID,
                clinicianID: clinicianID,
                locale: locale,
                threshold: threshold,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a shift rollup in status draft.
    static func newShiftRollup(_ code: String, label: String) -> ShiftRollup {
        return ShiftRollup(
            code: code,
            label: label,
            minimum: 0.0,
            ownerID: "",
            clinicianID: "",
            locale: "",
            threshold: 0.0,
            segment: "",
            status: ShiftRollupStatus.draft
        )
    }
}
