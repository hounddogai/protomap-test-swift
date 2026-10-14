import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered alert segment is in its life cycle.
    enum TieredAlertSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered alert segment as the alert team keeps it.
    final class TieredAlertSegment {
        var code: String
        var label: String
        var reviewer: String
        var summary: String
        var bed: String
        var margin: Double
        var copay: Double
        var ceiling: Double
        var status: TieredAlertSegmentStatus

        init(code: String, label: String, reviewer: String, summary: String, bed: String, margin: Double, copay: Double, ceiling: Double, status: TieredAlertSegmentStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.summary = summary
            self.bed = bed
            self.margin = margin
            self.copay = copay
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

        func canMoveTo(_ next: TieredAlertSegmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == TieredAlertSegmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredAlertSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered alert segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered alert segment") \(code)"
        }

        func weightedLoad() -> Double {
            return ((copay + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> TieredAlertSegment {
            return TieredAlertSegment(
                code: code,
                label: label,
                reviewer: reviewer,
                summary: summary,
                bed: bed,
                margin: margin,
                copay: copay,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered alert segment in status idle.
    static func newTieredAlertSegment(_ code: String, label: String) -> TieredAlertSegment {
        return TieredAlertSegment(
            code: code,
            label: label,
            reviewer: "",
            summary: "",
            bed: "",
            margin: 0.0,
            copay: 0.0,
            ceiling: 0.0,
            status: TieredAlertSegmentStatus.idle
        )
    }
}
