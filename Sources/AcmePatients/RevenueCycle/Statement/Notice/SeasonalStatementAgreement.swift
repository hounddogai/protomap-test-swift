import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a seasonal statement agreement is in its life cycle.
    enum SeasonalStatementAgreementStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One seasonal statement agreement, with what the planners need to act on it.
    final class SeasonalStatementAgreement {
        var code: String
        var name: String
        var retries: Int
        var currency: String
        var attributes: [String: String]
        var segment: String
        var priority: Int
        var expiresAt: Int
        var timezone: String
        var ratio: Double
        var status: SeasonalStatementAgreementStatus

        init(code: String, name: String, retries: Int, currency: String, attributes: [String: String], segment: String, priority: Int, expiresAt: Int, timezone: String, ratio: Double, status: SeasonalStatementAgreementStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.currency = currency
            self.attributes = attributes
            self.segment = segment
            self.priority = priority
            self.expiresAt = expiresAt
            self.timezone = timezone
            self.ratio = ratio
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

        func canMoveTo(_ next: SeasonalStatementAgreementStatus) -> Bool {
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
                return next == SeasonalStatementAgreementStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == SeasonalStatementAgreementStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalStatementAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal statement agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal statement agreement") \(code)"
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

        func adjustedLoad() -> Double {
            return ((Double(retries) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalStatementAgreement {
            return SeasonalStatementAgreement(
                code: code,
                name: name,
                retries: retries,
                currency: currency,
                attributes: attributes,
                segment: segment,
                priority: priority,
                expiresAt: expiresAt,
                timezone: timezone,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a seasonal statement agreement in status planned.
    static func newSeasonalStatementAgreement(_ code: String, name: String) -> SeasonalStatementAgreement {
        return SeasonalStatementAgreement(
            code: code,
            name: name,
            retries: 0,
            currency: "",
            attributes: [:],
            segment: "",
            priority: 0,
            expiresAt: 0,
            timezone: "",
            ratio: 0.0,
            status: SeasonalStatementAgreementStatus.planned
        )
    }
}
