import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form estimate is in its life cycle.
    enum ConsentFormEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a consent form estimate and its current status.
    final class ConsentFormEstimate {
        var code: String
        var title: String
        var batchSize: Int
        var visitMinutes: Int
        var amount: Double
        var currency: String
        var summary: String
        var timezone: String
        var status: ConsentFormEstimateStatus

        init(code: String, title: String, batchSize: Int, visitMinutes: Int, amount: Double, currency: String, summary: String, timezone: String, status: ConsentFormEstimateStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.visitMinutes = visitMinutes
            self.amount = amount
            self.currency = currency
            self.summary = summary
            self.timezone = timezone
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

        func canMoveTo(_ next: ConsentFormEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == ConsentFormEstimateStatus.granted || next == ConsentFormEstimateStatus.expired
            case .granted:
                return next == ConsentFormEstimateStatus.expired
            case .revoked:
                return next == ConsentFormEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return ((Double(visitMinutes) + amount) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormEstimate {
            return ConsentFormEstimate(
                code: code,
                title: title,
                batchSize: batchSize,
                visitMinutes: visitMinutes,
                amount: amount,
                currency: currency,
                summary: summary,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a consent form estimate in status requested.
    static func newConsentFormEstimate(_ code: String, title: String) -> ConsentFormEstimate {
        return ConsentFormEstimate(
            code: code,
            title: title,
            batchSize: 0,
            visitMinutes: 0,
            amount: 0.0,
            currency: "",
            summary: "",
            timezone: "",
            status: ConsentFormEstimateStatus.requested
        )
    }
}
