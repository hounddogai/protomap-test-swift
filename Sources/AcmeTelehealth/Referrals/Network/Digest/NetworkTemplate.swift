import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network template is in its life cycle.
    enum NetworkTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One network template, with what the planners need to act on it.
    final class NetworkTemplate {
        var code: String
        var label: String
        var dosageMg: Double
        var maximum: Double
        var minimum: Double
        var startsAt: Int
        var checksum: String
        var summary: String
        var region: String
        var status: NetworkTemplateStatus

        init(code: String, label: String, dosageMg: Double, maximum: Double, minimum: Double, startsAt: Int, checksum: String, summary: String, region: String, status: NetworkTemplateStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.maximum = maximum
            self.minimum = minimum
            self.startsAt = startsAt
            self.checksum = checksum
            self.summary = summary
            self.region = region
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

        func canMoveTo(_ next: NetworkTemplateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == NetworkTemplateStatus.completed || next == NetworkTemplateStatus.cancelled
            case .inProgress:
                return next == NetworkTemplateStatus.completed || next == NetworkTemplateStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: NetworkTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("network template") \(code)"
        }

        func effectiveValue() -> Double {
            return ((maximum + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkTemplate {
            return NetworkTemplate(
                code: code,
                label: label,
                dosageMg: dosageMg,
                maximum: maximum,
                minimum: minimum,
                startsAt: startsAt,
                checksum: checksum,
                summary: summary,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a network template in status planned.
    static func newNetworkTemplate(_ code: String, label: String) -> NetworkTemplate {
        return NetworkTemplate(
            code: code,
            label: label,
            dosageMg: 0.0,
            maximum: 0.0,
            minimum: 0.0,
            startsAt: 0,
            checksum: "",
            summary: "",
            region: "",
            status: NetworkTemplateStatus.planned
        )
    }
}
