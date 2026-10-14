import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive rounding metric is in its life cycle.
    enum AdaptiveRoundingMetricStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One adaptive rounding metric, with what the planners need to act on it.
    final class AdaptiveRoundingMetric {
        var code: String
        var title: String
        var createdAt: Int
        var region: String
        var minimum: Double
        var ratio: Double
        var name: String
        var retries: Int
        var unit: String
        var status: AdaptiveRoundingMetricStatus

        init(code: String, title: String, createdAt: Int, region: String, minimum: Double, ratio: Double, name: String, retries: Int, unit: String, status: AdaptiveRoundingMetricStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.region = region
            self.minimum = minimum
            self.ratio = ratio
            self.name = name
            self.retries = retries
            self.unit = unit
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

        func canMoveTo(_ next: AdaptiveRoundingMetricStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveRoundingMetricStatus.active
            case .pending:
                return next == AdaptiveRoundingMetricStatus.active || next == AdaptiveRoundingMetricStatus.suspended
            case .active:
                return next == AdaptiveRoundingMetricStatus.suspended || next == AdaptiveRoundingMetricStatus.closed
            case .suspended:
                return next == AdaptiveRoundingMetricStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRoundingMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive rounding metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return (Double(retries) * minimum * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRoundingMetric {
            return AdaptiveRoundingMetric(
                code: code,
                title: title,
                createdAt: createdAt,
                region: region,
                minimum: minimum,
                ratio: ratio,
                name: name,
                retries: retries,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a adaptive rounding metric in status draft.
    static func newAdaptiveRoundingMetric(_ code: String, title: String) -> AdaptiveRoundingMetric {
        return AdaptiveRoundingMetric(
            code: code,
            title: title,
            createdAt: 0,
            region: "",
            minimum: 0.0,
            ratio: 0.0,
            name: "",
            retries: 0,
            unit: "",
            status: AdaptiveRoundingMetricStatus.draft
        )
    }
}
