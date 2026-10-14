import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback rounding metric is in its life cycle.
    enum FallbackRoundingMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a fallback rounding metric and its current status.
    final class FallbackRoundingMetric {
        var code: String
        var name: String
        var startsAt: Int
        var maximum: Double
        var checksum: String
        var floorValue: Double
        var patientRef: String
        var status: FallbackRoundingMetricStatus

        init(code: String, name: String, startsAt: Int, maximum: Double, checksum: String, floorValue: Double, patientRef: String, status: FallbackRoundingMetricStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.maximum = maximum
            self.checksum = checksum
            self.floorValue = floorValue
            self.patientRef = patientRef
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

        func canMoveTo(_ next: FallbackRoundingMetricStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FallbackRoundingMetricStatus.inProgress || next == FallbackRoundingMetricStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FallbackRoundingMetricStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackRoundingMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback rounding metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return ((Double(startsAt) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRoundingMetric {
            return FallbackRoundingMetric(
                code: code,
                name: name,
                startsAt: startsAt,
                maximum: maximum,
                checksum: checksum,
                floorValue: floorValue,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback rounding metric in status planned.
    static func newFallbackRoundingMetric(_ code: String, name: String) -> FallbackRoundingMetric {
        return FallbackRoundingMetric(
            code: code,
            name: name,
            startsAt: 0,
            maximum: 0.0,
            checksum: "",
            floorValue: 0.0,
            patientRef: "",
            status: FallbackRoundingMetricStatus.planned
        )
    }
}
