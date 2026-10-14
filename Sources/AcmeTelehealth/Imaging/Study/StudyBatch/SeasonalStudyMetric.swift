import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal study metric is in its life cycle.
    enum SeasonalStudyMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a seasonal study metric and its current status.
    final class SeasonalStudyMetric {
        var code: String
        var label: String
        var active: Bool
        var batchSize: Int
        var ward: String
        var endsAt: Int
        var timezone: String
        var title: String
        var bed: String
        var durationMinutes: Int
        var rate: Double
        var status: SeasonalStudyMetricStatus

        init(code: String, label: String, active: Bool, batchSize: Int, ward: String, endsAt: Int, timezone: String, title: String, bed: String, durationMinutes: Int, rate: Double, status: SeasonalStudyMetricStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.batchSize = batchSize
            self.ward = ward
            self.endsAt = endsAt
            self.timezone = timezone
            self.title = title
            self.bed = bed
            self.durationMinutes = durationMinutes
            self.rate = rate
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

        func canMoveTo(_ next: SeasonalStudyMetricStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SeasonalStudyMetricStatus.inReview || next == SeasonalStudyMetricStatus.archived
            case .inReview:
                return next == SeasonalStudyMetricStatus.reopened || next == SeasonalStudyMetricStatus.archived
            case .resolved:
                return next == SeasonalStudyMetricStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: SeasonalStudyMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal study metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedVolume() -> Double {
            return ((Double(endsAt) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalStudyMetric {
            return SeasonalStudyMetric(
                code: code,
                label: label,
                active: active,
                batchSize: batchSize,
                ward: ward,
                endsAt: endsAt,
                timezone: timezone,
                title: title,
                bed: bed,
                durationMinutes: durationMinutes,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a seasonal study metric in status open.
    static func newSeasonalStudyMetric(_ code: String, label: String) -> SeasonalStudyMetric {
        return SeasonalStudyMetric(
            code: code,
            label: label,
            active: false,
            batchSize: 0,
            ward: "",
            endsAt: 0,
            timezone: "",
            title: "",
            bed: "",
            durationMinutes: 0,
            rate: 0.0,
            status: SeasonalStudyMetricStatus.`open`
        )
    }
}
