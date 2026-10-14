import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive eligibility forecast is in its life cycle.
    enum AdaptiveEligibilityForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One adaptive eligibility forecast, with what the planners need to act on it.
    final class AdaptiveEligibilityForecast {
        var code: String
        var name: String
        var channel: String
        var category: String
        var country: String
        var margin: Double
        var cost: Double
        var patientRef: String
        var locale: String
        var createdAt: Int
        var status: AdaptiveEligibilityForecastStatus

        init(code: String, name: String, channel: String, category: String, country: String, margin: Double, cost: Double, patientRef: String, locale: String, createdAt: Int, status: AdaptiveEligibilityForecastStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.category = category
            self.country = country
            self.margin = margin
            self.cost = cost
            self.patientRef = patientRef
            self.locale = locale
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveEligibilityForecastStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveEligibilityForecastStatus.inReview || next == AdaptiveEligibilityForecastStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AdaptiveEligibilityForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive eligibility forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive eligibility forecast") \(code)"
        }

        func netValue() -> Double {
            return ((cost + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveEligibilityForecast {
            return AdaptiveEligibilityForecast(
                code: code,
                name: name,
                channel: channel,
                category: category,
                country: country,
                margin: margin,
                cost: cost,
                patientRef: patientRef,
                locale: locale,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive eligibility forecast in status open.
    static func newAdaptiveEligibilityForecast(_ code: String, name: String) -> AdaptiveEligibilityForecast {
        return AdaptiveEligibilityForecast(
            code: code,
            name: name,
            channel: "",
            category: "",
            country: "",
            margin: 0.0,
            cost: 0.0,
            patientRef: "",
            locale: "",
            createdAt: 0,
            status: AdaptiveEligibilityForecastStatus.`open`
        )
    }
}
