import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy care protocol threshold is in its life cycle.
    enum LegacyCareProtocolThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A legacy care protocol threshold as the care protocol team keeps it.
    final class LegacyCareProtocolThreshold {
        var code: String
        var title: String
        var acuity: Int
        var weight: Double
        var amount: Double
        var margin: Double
        var currency: String
        var visitMinutes: Int
        var bed: String
        var version: Int
        var status: LegacyCareProtocolThresholdStatus

        init(code: String, title: String, acuity: Int, weight: Double, amount: Double, margin: Double, currency: String, visitMinutes: Int, bed: String, version: Int, status: LegacyCareProtocolThresholdStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.weight = weight
            self.amount = amount
            self.margin = margin
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.bed = bed
            self.version = version
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

        func canMoveTo(_ next: LegacyCareProtocolThresholdStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LegacyCareProtocolThresholdStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LegacyCareProtocolThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy care protocol threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netValue() -> Double {
            return (amount * weight * 100).rounded() / 100
        }

        func copyValue() -> LegacyCareProtocolThreshold {
            return LegacyCareProtocolThreshold(
                code: code,
                title: title,
                acuity: acuity,
                weight: weight,
                amount: amount,
                margin: margin,
                currency: currency,
                visitMinutes: visitMinutes,
                bed: bed,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy care protocol threshold in status created.
    static func newLegacyCareProtocolThreshold(_ code: String, title: String) -> LegacyCareProtocolThreshold {
        return LegacyCareProtocolThreshold(
            code: code,
            title: title,
            acuity: 0,
            weight: 0.0,
            amount: 0.0,
            margin: 0.0,
            currency: "",
            visitMinutes: 0,
            bed: "",
            version: 0,
            status: LegacyCareProtocolThresholdStatus.created
        )
    }
}
