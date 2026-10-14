import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure segment is in its life cycle.
    enum DisclosureSegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A disclosure segment as the disclosure team keeps it.
    final class DisclosureSegment {
        var code: String
        var title: String
        var threshold: Double
        var margin: Double
        var name: String
        var refills: Int
        var status: DisclosureSegmentStatus

        init(code: String, title: String, threshold: Double, margin: Double, name: String, refills: Int, status: DisclosureSegmentStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.margin = margin
            self.name = name
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DisclosureSegmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == DisclosureSegmentStatus.scheduled || next == DisclosureSegmentStatus.inProgress
            case .scheduled:
                return next == DisclosureSegmentStatus.inProgress || next == DisclosureSegmentStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == DisclosureSegmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("disclosure segment") \(code)"
        }

        func weightedTotal() -> Double {
            return (threshold * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureSegment {
            return DisclosureSegment(
                code: code,
                title: title,
                threshold: threshold,
                margin: margin,
                name: name,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a disclosure segment in status planned.
    static func newDisclosureSegment(_ code: String, title: String) -> DisclosureSegment {
        return DisclosureSegment(
            code: code,
            title: title,
            threshold: 0.0,
            margin: 0.0,
            name: "",
            refills: 0,
            status: DisclosureSegmentStatus.planned
        )
    }
}
