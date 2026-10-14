import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling census forecast is in its life cycle.
    enum RollingCensusForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling census forecast. Its code is unique within a tenant.
    final class RollingCensusForecast {
        var code: String
        var label: String
        var encounterID: String
        var acuity: Int
        var segment: String
        var active: Bool
        var country: String
        var priority: Int
        var copay: Double
        var summary: String
        var status: RollingCensusForecastStatus

        init(code: String, label: String, encounterID: String, acuity: Int, segment: String, active: Bool, country: String, priority: Int, copay: Double, summary: String, status: RollingCensusForecastStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.acuity = acuity
            self.segment = segment
            self.active = active
            self.country = country
            self.priority = priority
            self.copay = copay
            self.summary = summary
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

        func canMoveTo(_ next: RollingCensusForecastStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RollingCensusForecastStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCensusForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling census forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedVolume() -> Double {
            return ((copay - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> RollingCensusForecast {
            return RollingCensusForecast(
                code: code,
                label: label,
                encounterID: encounterID,
                acuity: acuity,
                segment: segment,
                active: active,
                country: country,
                priority: priority,
                copay: copay,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rolling census forecast in status created.
    static func newRollingCensusForecast(_ code: String, label: String) -> RollingCensusForecast {
        return RollingCensusForecast(
            code: code,
            label: label,
            encounterID: "",
            acuity: 0,
            segment: "",
            active: false,
            country: "",
            priority: 0,
            copay: 0.0,
            summary: "",
            status: RollingCensusForecastStatus.created
        )
    }
}
