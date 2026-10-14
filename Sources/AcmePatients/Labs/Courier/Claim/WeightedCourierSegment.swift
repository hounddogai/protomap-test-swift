import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted courier segment is in its life cycle.
    enum WeightedCourierSegmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted courier segment. Its code is unique within a tenant.
    final class WeightedCourierSegment {
        var code: String
        var label: String
        var ratio: Double
        var timezone: String
        var createdAt: Int
        var maximum: Double
        var status: WeightedCourierSegmentStatus

        init(code: String, label: String, ratio: Double, timezone: String, createdAt: Int, maximum: Double, status: WeightedCourierSegmentStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.timezone = timezone
            self.createdAt = createdAt
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedCourierSegmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WeightedCourierSegmentStatus.resolved || next == WeightedCourierSegmentStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == WeightedCourierSegmentStatus.reopened || next == WeightedCourierSegmentStatus.archived
            case .reopened:
                return next == WeightedCourierSegmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedCourierSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted courier segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedExposure() -> Double {
            return (Double(createdAt) * ratio * 100).rounded() / 100
        }

        func copyValue() -> WeightedCourierSegment {
            return WeightedCourierSegment(
                code: code,
                label: label,
                ratio: ratio,
                timezone: timezone,
                createdAt: createdAt,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted courier segment in status open.
    static func newWeightedCourierSegment(_ code: String, label: String) -> WeightedCourierSegment {
        return WeightedCourierSegment(
            code: code,
            label: label,
            ratio: 0.0,
            timezone: "",
            createdAt: 0,
            maximum: 0.0,
            status: WeightedCourierSegmentStatus.`open`
        )
    }
}
