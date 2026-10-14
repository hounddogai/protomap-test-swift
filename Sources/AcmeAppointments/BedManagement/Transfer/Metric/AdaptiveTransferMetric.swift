import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive transfer metric is in its life cycle.
    enum AdaptiveTransferMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive transfer metric as the transfer team keeps it.
    final class AdaptiveTransferMetric {
        var code: String
        var title: String
        var discount: Double
        var startsAt: Int
        var attempts: Int
        var retries: Int
        var timezone: String
        var sequence: Int
        var cost: Double
        var attributes: [String: String]
        var segment: String
        var status: AdaptiveTransferMetricStatus

        init(code: String, title: String, discount: Double, startsAt: Int, attempts: Int, retries: Int, timezone: String, sequence: Int, cost: Double, attributes: [String: String], segment: String, status: AdaptiveTransferMetricStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.startsAt = startsAt
            self.attempts = attempts
            self.retries = retries
            self.timezone = timezone
            self.sequence = sequence
            self.cost = cost
            self.attributes = attributes
            self.segment = segment
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

        func canMoveTo(_ next: AdaptiveTransferMetricStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveTransferMetricStatus.expired
            case .granted:
                return next == AdaptiveTransferMetricStatus.expired
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

        func moveTo(_ next: AdaptiveTransferMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive transfer metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netLoad() -> Double {
            return (Double(attempts) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveTransferMetric {
            return AdaptiveTransferMetric(
                code: code,
                title: title,
                discount: discount,
                startsAt: startsAt,
                attempts: attempts,
                retries: retries,
                timezone: timezone,
                sequence: sequence,
                cost: cost,
                attributes: attributes,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive transfer metric in status requested.
    static func newAdaptiveTransferMetric(_ code: String, title: String) -> AdaptiveTransferMetric {
        return AdaptiveTransferMetric(
            code: code,
            title: title,
            discount: 0.0,
            startsAt: 0,
            attempts: 0,
            retries: 0,
            timezone: "",
            sequence: 0,
            cost: 0.0,
            attributes: [:],
            segment: "",
            status: AdaptiveTransferMetricStatus.requested
        )
    }
}
