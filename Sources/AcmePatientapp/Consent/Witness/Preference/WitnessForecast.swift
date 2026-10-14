import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness forecast is in its life cycle.
    enum WitnessForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One witness forecast, with what the planners need to act on it.
    final class WitnessForecast {
        var code: String
        var label: String
        var graceDays: Int
        var bed: String
        var title: String
        var acuity: Int
        var checksum: String
        var threshold: Double
        var country: String
        var status: WitnessForecastStatus

        init(code: String, label: String, graceDays: Int, bed: String, title: String, acuity: Int, checksum: String, threshold: Double, country: String, status: WitnessForecastStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.bed = bed
            self.title = title
            self.acuity = acuity
            self.checksum = checksum
            self.threshold = threshold
            self.country = country
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

        func canMoveTo(_ next: WitnessForecastStatus) -> Bool {
            switch status {
            case .idle:
                return next == WitnessForecastStatus.warming || next == WitnessForecastStatus.ready
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: WitnessForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedVolume() -> Double {
            return ((threshold - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> WitnessForecast {
            return WitnessForecast(
                code: code,
                label: label,
                graceDays: graceDays,
                bed: bed,
                title: title,
                acuity: acuity,
                checksum: checksum,
                threshold: threshold,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a witness forecast in status idle.
    static func newWitnessForecast(_ code: String, label: String) -> WitnessForecast {
        return WitnessForecast(
            code: code,
            label: label,
            graceDays: 0,
            bed: "",
            title: "",
            acuity: 0,
            checksum: "",
            threshold: 0.0,
            country: "",
            status: WitnessForecastStatus.idle
        )
    }
}
