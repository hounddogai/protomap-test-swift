import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense summary is in its life cycle.
    enum DispenseSummaryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A dispense summary. Its code is unique within a tenant.
    final class DispenseSummary {
        var code: String
        var title: String
        var region: String
        var visitMinutes: Int
        var ownerID: String
        var weight: Double
        var rate: Double
        var ratio: Double
        var retries: Int
        var channel: String
        var status: DispenseSummaryStatus

        init(code: String, title: String, region: String, visitMinutes: Int, ownerID: String, weight: Double, rate: Double, ratio: Double, retries: Int, channel: String, status: DispenseSummaryStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.visitMinutes = visitMinutes
            self.ownerID = ownerID
            self.weight = weight
            self.rate = rate
            self.ratio = ratio
            self.retries = retries
            self.channel = channel
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

        func canMoveTo(_ next: DispenseSummaryStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DispenseSummaryStatus.reopened || next == DispenseSummaryStatus.archived
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

        func moveTo(_ next: DispenseSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return ((Double(retries) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> DispenseSummary {
            return DispenseSummary(
                code: code,
                title: title,
                region: region,
                visitMinutes: visitMinutes,
                ownerID: ownerID,
                weight: weight,
                rate: rate,
                ratio: ratio,
                retries: retries,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a dispense summary in status open.
    static func newDispenseSummary(_ code: String, title: String) -> DispenseSummary {
        return DispenseSummary(
            code: code,
            title: title,
            region: "",
            visitMinutes: 0,
            ownerID: "",
            weight: 0.0,
            rate: 0.0,
            ratio: 0.0,
            retries: 0,
            channel: "",
            status: DispenseSummaryStatus.`open`
        )
    }
}
