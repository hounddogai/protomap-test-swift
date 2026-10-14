import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial quota is in its life cycle.
    enum DenialQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A denial quota as the denial team keeps it.
    final class DenialQuota {
        var code: String
        var name: String
        var country: String
        var timezone: String
        var rate: Double
        var ceiling: Double
        var score: Double
        var status: DenialQuotaStatus

        init(code: String, name: String, country: String, timezone: String, rate: Double, ceiling: Double, score: Double, status: DenialQuotaStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.timezone = timezone
            self.rate = rate
            self.ceiling = ceiling
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DenialQuotaStatus) -> Bool {
            switch status {
            case .new:
                return next == DenialQuotaStatus.done || next == DenialQuotaStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == DenialQuotaStatus.done || next == DenialQuotaStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: DenialQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveValue() -> Double {
            return (score * rate * 100).rounded() / 100
        }

        func copyValue() -> DenialQuota {
            return DenialQuota(
                code: code,
                name: name,
                country: country,
                timezone: timezone,
                rate: rate,
                ceiling: ceiling,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a denial quota in status new.
    static func newDenialQuota(_ code: String, name: String) -> DenialQuota {
        return DenialQuota(
            code: code,
            name: name,
            country: "",
            timezone: "",
            rate: 0.0,
            ceiling: 0.0,
            score: 0.0,
            status: DenialQuotaStatus.new
        )
    }
}
