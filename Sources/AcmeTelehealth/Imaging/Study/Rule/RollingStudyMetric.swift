import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling study metric is in its life cycle.
    enum RollingStudyMetricStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rolling study metric, with what the planners need to act on it.
    final class RollingStudyMetric {
        var code: String
        var name: String
        var externalRef: String
        var startsAt: Int
        var unit: String
        var maximum: Double
        var createdAt: Int
        var revision: Int
        var floorValue: Double
        var status: RollingStudyMetricStatus

        init(code: String, name: String, externalRef: String, startsAt: Int, unit: String, maximum: Double, createdAt: Int, revision: Int, floorValue: Double, status: RollingStudyMetricStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.unit = unit
            self.maximum = maximum
            self.createdAt = createdAt
            self.revision = revision
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingStudyMetricStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingStudyMetricStatus.retired
            case .validated:
                return next == RollingStudyMetricStatus.published || next == RollingStudyMetricStatus.retired
            case .published:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingStudyMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling study metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("rolling study metric") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(createdAt) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingStudyMetric {
            return RollingStudyMetric(
                code: code,
                name: name,
                externalRef: externalRef,
                startsAt: startsAt,
                unit: unit,
                maximum: maximum,
                createdAt: createdAt,
                revision: revision,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rolling study metric in status created.
    static func newRollingStudyMetric(_ code: String, name: String) -> RollingStudyMetric {
        return RollingStudyMetric(
            code: code,
            name: name,
            externalRef: "",
            startsAt: 0,
            unit: "",
            maximum: 0.0,
            createdAt: 0,
            revision: 0,
            floorValue: 0.0,
            status: RollingStudyMetricStatus.created
        )
    }
}
