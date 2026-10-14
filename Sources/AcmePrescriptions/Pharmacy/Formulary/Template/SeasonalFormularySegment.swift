import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal formulary segment is in its life cycle.
    enum SeasonalFormularySegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One seasonal formulary segment, with what the planners need to act on it.
    final class SeasonalFormularySegment {
        var code: String
        var label: String
        var minimum: Double
        var threshold: Double
        var summary: String
        var ceiling: Double
        var status: SeasonalFormularySegmentStatus

        init(code: String, label: String, minimum: Double, threshold: Double, summary: String, ceiling: Double, status: SeasonalFormularySegmentStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.threshold = threshold
            self.summary = summary
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalFormularySegmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == SeasonalFormularySegmentStatus.warming || next == SeasonalFormularySegmentStatus.ready
            case .warming:
                return next == SeasonalFormularySegmentStatus.stopped
            case .ready:
                return next == SeasonalFormularySegmentStatus.draining
            case .draining:
                return next == SeasonalFormularySegmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalFormularySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal formulary segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return (minimum * ceiling * 100).rounded() / 100
        }

        func copyValue() -> SeasonalFormularySegment {
            return SeasonalFormularySegment(
                code: code,
                label: label,
                minimum: minimum,
                threshold: threshold,
                summary: summary,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal formulary segment in status idle.
    static func newSeasonalFormularySegment(_ code: String, label: String) -> SeasonalFormularySegment {
        return SeasonalFormularySegment(
            code: code,
            label: label,
            minimum: 0.0,
            threshold: 0.0,
            summary: "",
            ceiling: 0.0,
            status: SeasonalFormularySegmentStatus.idle
        )
    }
}
