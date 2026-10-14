import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary result summary is in its life cycle.
    enum PrimaryResultSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary result summary. Its code is unique within a tenant.
    final class PrimaryResultSummary {
        var code: String
        var name: String
        var maximum: Double
        var ratio: Double
        var source: String
        var limit: Int
        var createdAt: Int
        var payer: String
        var currency: String
        var startsAt: Int
        var status: PrimaryResultSummaryStatus

        init(code: String, name: String, maximum: Double, ratio: Double, source: String, limit: Int, createdAt: Int, payer: String, currency: String, startsAt: Int, status: PrimaryResultSummaryStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.ratio = ratio
            self.source = source
            self.limit = limit
            self.createdAt = createdAt
            self.payer = payer
            self.currency = currency
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryResultSummaryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PrimaryResultSummaryStatus.closed
            case .active:
                return next == PrimaryResultSummaryStatus.suspended || next == PrimaryResultSummaryStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PrimaryResultSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary result summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedValue() -> Double {
            return (maximum * ratio * 100).rounded() / 100
        }

        func copyValue() -> PrimaryResultSummary {
            return PrimaryResultSummary(
                code: code,
                name: name,
                maximum: maximum,
                ratio: ratio,
                source: source,
                limit: limit,
                createdAt: createdAt,
                payer: payer,
                currency: currency,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary result summary in status draft.
    static func newPrimaryResultSummary(_ code: String, name: String) -> PrimaryResultSummary {
        return PrimaryResultSummary(
            code: code,
            name: name,
            maximum: 0.0,
            ratio: 0.0,
            source: "",
            limit: 0,
            createdAt: 0,
            payer: "",
            currency: "",
            startsAt: 0,
            status: PrimaryResultSummaryStatus.draft
        )
    }
}
