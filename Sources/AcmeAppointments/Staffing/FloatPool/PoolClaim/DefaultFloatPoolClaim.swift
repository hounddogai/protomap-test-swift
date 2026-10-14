import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default float pool claim is in its life cycle.
    enum DefaultFloatPoolClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default float pool claim as the float pool team keeps it.
    final class DefaultFloatPoolClaim {
        var code: String
        var label: String
        var limit: Int
        var unit: String
        var channel: String
        var cost: Double
        var locale: String
        var externalRef: String
        var status: DefaultFloatPoolClaimStatus

        init(code: String, label: String, limit: Int, unit: String, channel: String, cost: Double, locale: String, externalRef: String, status: DefaultFloatPoolClaimStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.unit = unit
            self.channel = channel
            self.cost = cost
            self.locale = locale
            self.externalRef = externalRef
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

        func canMoveTo(_ next: DefaultFloatPoolClaimStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultFloatPoolClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default float pool claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return ((cost + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultFloatPoolClaim {
            return DefaultFloatPoolClaim(
                code: code,
                label: label,
                limit: limit,
                unit: unit,
                channel: channel,
                cost: cost,
                locale: locale,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a default float pool claim in status planned.
    static func newDefaultFloatPoolClaim(_ code: String, label: String) -> DefaultFloatPoolClaim {
        return DefaultFloatPoolClaim(
            code: code,
            label: label,
            limit: 0,
            unit: "",
            channel: "",
            cost: 0.0,
            locale: "",
            externalRef: "",
            status: DefaultFloatPoolClaimStatus.planned
        )
    }
}
