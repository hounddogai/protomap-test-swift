import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy profile is in its life cycle.
    enum ProxyProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A proxy profile as the proxy team keeps it.
    final class ProxyProfile {
        var code: String
        var title: String
        var country: String
        var ratio: Double
        var diagnosisCode: String
        var region: String
        var name: String
        var facility: String
        var version: Int
        var threshold: Double
        var status: ProxyProfileStatus

        init(code: String, title: String, country: String, ratio: Double, diagnosisCode: String, region: String, name: String, facility: String, version: Int, threshold: Double, status: ProxyProfileStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.ratio = ratio
            self.diagnosisCode = diagnosisCode
            self.region = region
            self.name = name
            self.facility = facility
            self.version = version
            self.threshold = threshold
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

        func canMoveTo(_ next: ProxyProfileStatus) -> Bool {
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
                return next == ProxyProfileStatus.inProgress || next == ProxyProfileStatus.cancelled
            case .inProgress:
                return next == ProxyProfileStatus.cancelled
            case .completed:
                return next == ProxyProfileStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return ((ratio + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyProfile {
            return ProxyProfile(
                code: code,
                title: title,
                country: country,
                ratio: ratio,
                diagnosisCode: diagnosisCode,
                region: region,
                name: name,
                facility: facility,
                version: version,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a proxy profile in status planned.
    static func newProxyProfile(_ code: String, title: String) -> ProxyProfile {
        return ProxyProfile(
            code: code,
            title: title,
            country: "",
            ratio: 0.0,
            diagnosisCode: "",
            region: "",
            name: "",
            facility: "",
            version: 0,
            threshold: 0.0,
            status: ProxyProfileStatus.planned
        )
    }
}
