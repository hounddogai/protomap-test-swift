import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback care gap summary is in its life cycle.
    enum FallbackCareGapSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback care gap summary as the care gap team keeps it.
    final class FallbackCareGapSummary {
        var code: String
        var label: String
        var version: Int
        var ratio: Double
        var timezone: String
        var region: String
        var status: FallbackCareGapSummaryStatus

        init(code: String, label: String, version: Int, ratio: Double, timezone: String, region: String, status: FallbackCareGapSummaryStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.ratio = ratio
            self.timezone = timezone
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackCareGapSummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackCareGapSummaryStatus.granted || next == FallbackCareGapSummaryStatus.expired
            case .granted:
                return next == FallbackCareGapSummaryStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: FallbackCareGapSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care gap summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(version) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCareGapSummary {
            return FallbackCareGapSummary(
                code: code,
                label: label,
                version: version,
                ratio: ratio,
                timezone: timezone,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback care gap summary in status requested.
    static func newFallbackCareGapSummary(_ code: String, label: String) -> FallbackCareGapSummary {
        return FallbackCareGapSummary(
            code: code,
            label: label,
            version: 0,
            ratio: 0.0,
            timezone: "",
            region: "",
            status: FallbackCareGapSummaryStatus.requested
        )
    }
}
