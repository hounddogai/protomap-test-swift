import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient substitution rollup is in its life cycle.
    enum LenientSubstitutionRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One lenient substitution rollup, with what the planners need to act on it.
    final class LenientSubstitutionRollup {
        var code: String
        var label: String
        var source: String
        var summary: String
        var ownerID: String
        var floorValue: Double
        var graceDays: Int
        var margin: Double
        var status: LenientSubstitutionRollupStatus

        init(code: String, label: String, source: String, summary: String, ownerID: String, floorValue: Double, graceDays: Int, margin: Double, status: LenientSubstitutionRollupStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.summary = summary
            self.ownerID = ownerID
            self.floorValue = floorValue
            self.graceDays = graceDays
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientSubstitutionRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientSubstitutionRollupStatus.queued
            case .queued:
                return next == LenientSubstitutionRollupStatus.running
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LenientSubstitutionRollupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientSubstitutionRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient substitution rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveTotal() -> Double {
            return ((floorValue - margin) * 100).rounded() / 100
        }

        func copyValue() -> LenientSubstitutionRollup {
            return LenientSubstitutionRollup(
                code: code,
                label: label,
                source: source,
                summary: summary,
                ownerID: ownerID,
                floorValue: floorValue,
                graceDays: graceDays,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient substitution rollup in status new.
    static func newLenientSubstitutionRollup(_ code: String, label: String) -> LenientSubstitutionRollup {
        return LenientSubstitutionRollup(
            code: code,
            label: label,
            source: "",
            summary: "",
            ownerID: "",
            floorValue: 0.0,
            graceDays: 0,
            margin: 0.0,
            status: LenientSubstitutionRollupStatus.new
        )
    }
}
