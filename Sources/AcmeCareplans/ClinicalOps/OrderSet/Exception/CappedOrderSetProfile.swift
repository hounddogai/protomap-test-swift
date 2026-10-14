import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped order set profile is in its life cycle.
    enum CappedOrderSetProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped order set profile as the order set team keeps it.
    final class CappedOrderSetProfile {
        var code: String
        var title: String
        var unit: String
        var graceDays: Int
        var score: Double
        var currency: String
        var rate: Double
        var timezone: String
        var retries: Int
        var status: CappedOrderSetProfileStatus

        init(code: String, title: String, unit: String, graceDays: Int, score: Double, currency: String, rate: Double, timezone: String, retries: Int, status: CappedOrderSetProfileStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.graceDays = graceDays
            self.score = score
            self.currency = currency
            self.rate = rate
            self.timezone = timezone
            self.retries = retries
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

        func canMoveTo(_ next: CappedOrderSetProfileStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedOrderSetProfileStatus.validated || next == CappedOrderSetProfileStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == CappedOrderSetProfileStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedOrderSetProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped order set profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return (rate * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> CappedOrderSetProfile {
            return CappedOrderSetProfile(
                code: code,
                title: title,
                unit: unit,
                graceDays: graceDays,
                score: score,
                currency: currency,
                rate: rate,
                timezone: timezone,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped order set profile in status created.
    static func newCappedOrderSetProfile(_ code: String, title: String) -> CappedOrderSetProfile {
        return CappedOrderSetProfile(
            code: code,
            title: title,
            unit: "",
            graceDays: 0,
            score: 0.0,
            currency: "",
            rate: 0.0,
            timezone: "",
            retries: 0,
            status: CappedOrderSetProfileStatus.created
        )
    }
}
