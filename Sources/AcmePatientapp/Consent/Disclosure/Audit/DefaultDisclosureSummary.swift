import AcmePlatform
import Foundation

extension Consent {
    /// Where a default disclosure summary is in its life cycle.
    enum DefaultDisclosureSummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a default disclosure summary and its current status.
    final class DefaultDisclosureSummary {
        var code: String
        var name: String
        var externalRef: String
        var minimum: Double
        var encounterID: String
        var procedureCode: String
        var allergy: String
        var timezone: String
        var locale: String
        var createdAt: Int
        var startsAt: Int
        var status: DefaultDisclosureSummaryStatus

        init(code: String, name: String, externalRef: String, minimum: Double, encounterID: String, procedureCode: String, allergy: String, timezone: String, locale: String, createdAt: Int, startsAt: Int, status: DefaultDisclosureSummaryStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.minimum = minimum
            self.encounterID = encounterID
            self.procedureCode = procedureCode
            self.allergy = allergy
            self.timezone = timezone
            self.locale = locale
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultDisclosureSummaryStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: DefaultDisclosureSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default disclosure summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default disclosure summary") \(code)"
        }

        func projectedLoad() -> Double {
            return (Double(startsAt) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> DefaultDisclosureSummary {
            return DefaultDisclosureSummary(
                code: code,
                name: name,
                externalRef: externalRef,
                minimum: minimum,
                encounterID: encounterID,
                procedureCode: procedureCode,
                allergy: allergy,
                timezone: timezone,
                locale: locale,
                createdAt: createdAt,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a default disclosure summary in status proposed.
    static func newDefaultDisclosureSummary(_ code: String, name: String) -> DefaultDisclosureSummary {
        return DefaultDisclosureSummary(
            code: code,
            name: name,
            externalRef: "",
            minimum: 0.0,
            encounterID: "",
            procedureCode: "",
            allergy: "",
            timezone: "",
            locale: "",
            createdAt: 0,
            startsAt: 0,
            status: DefaultDisclosureSummaryStatus.proposed
        )
    }
}
