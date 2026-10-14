import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal priority metric is in its life cycle.
    enum SeasonalPriorityMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal priority metric. Its code is unique within a tenant.
    final class SeasonalPriorityMetric {
        var code: String
        var label: String
        var bed: String
        var limit: Int
        var ward: String
        var rate: Double
        var floorValue: Double
        var status: SeasonalPriorityMetricStatus

        init(code: String, label: String, bed: String, limit: Int, ward: String, rate: Double, floorValue: Double, status: SeasonalPriorityMetricStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.limit = limit
            self.ward = ward
            self.rate = rate
            self.floorValue = floorValue
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

        func canMoveTo(_ next: SeasonalPriorityMetricStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == SeasonalPriorityMetricStatus.revoked || next == SeasonalPriorityMetricStatus.expired
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

        func moveTo(_ next: SeasonalPriorityMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal priority metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return ((Double(limit) - rate) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalPriorityMetric {
            return SeasonalPriorityMetric(
                code: code,
                label: label,
                bed: bed,
                limit: limit,
                ward: ward,
                rate: rate,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a seasonal priority metric in status requested.
    static func newSeasonalPriorityMetric(_ code: String, label: String) -> SeasonalPriorityMetric {
        return SeasonalPriorityMetric(
            code: code,
            label: label,
            bed: "",
            limit: 0,
            ward: "",
            rate: 0.0,
            floorValue: 0.0,
            status: SeasonalPriorityMetricStatus.requested
        )
    }
}
