import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range forecast is in its life cycle.
    enum ReferenceRangeForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a reference range forecast and its current status.
    final class ReferenceRangeForecast {
        var code: String
        var title: String
        var minimum: Double
        var amount: Double
        var startsAt: Int
        var retries: Int
        var segment: String
        var region: String
        var quantity: Int
        var status: ReferenceRangeForecastStatus

        init(code: String, title: String, minimum: Double, amount: Double, startsAt: Int, retries: Int, segment: String, region: String, quantity: Int, status: ReferenceRangeForecastStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.amount = amount
            self.startsAt = startsAt
            self.retries = retries
            self.segment = segment
            self.region = region
            self.quantity = quantity
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

        func canMoveTo(_ next: ReferenceRangeForecastStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ReferenceRangeForecastStatus.resolved
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

        func moveTo(_ next: ReferenceRangeForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("reference range forecast") \(code)"
        }

        func adjustedValue() -> Double {
            return ((minimum - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeForecast {
            return ReferenceRangeForecast(
                code: code,
                title: title,
                minimum: minimum,
                amount: amount,
                startsAt: startsAt,
                retries: retries,
                segment: segment,
                region: region,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a reference range forecast in status open.
    static func newReferenceRangeForecast(_ code: String, title: String) -> ReferenceRangeForecast {
        return ReferenceRangeForecast(
            code: code,
            title: title,
            minimum: 0.0,
            amount: 0.0,
            startsAt: 0,
            retries: 0,
            segment: "",
            region: "",
            quantity: 0,
            status: ReferenceRangeForecastStatus.`open`
        )
    }
}
