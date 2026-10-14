import AcmePlatform
import Foundation

extension Labs {
    /// Where a result summary is in its life cycle.
    enum ResultSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One result summary, with what the planners need to act on it.
    final class ResultSummary {
        var code: String
        var label: String
        var description: String
        var source: String
        var allergy: String
        var version: Int
        var currency: String
        var visitMinutes: Int
        var pinned: Bool
        var rate: Double
        var status: ResultSummaryStatus

        init(code: String, label: String, description: String, source: String, allergy: String, version: Int, currency: String, visitMinutes: Int, pinned: Bool, rate: Double, status: ResultSummaryStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.source = source
            self.allergy = allergy
            self.version = version
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.pinned = pinned
            self.rate = rate
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

        func canMoveTo(_ next: ResultSummaryStatus) -> Bool {
            switch status {
            case .draft:
                return next == ResultSummaryStatus.suspended
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ResultSummaryStatus.closed
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

        func moveTo(_ next: ResultSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedTotal() -> Double {
            return (Double(version) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ResultSummary {
            return ResultSummary(
                code: code,
                label: label,
                description: description,
                source: source,
                allergy: allergy,
                version: version,
                currency: currency,
                visitMinutes: visitMinutes,
                pinned: pinned,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a result summary in status draft.
    static func newResultSummary(_ code: String, label: String) -> ResultSummary {
        return ResultSummary(
            code: code,
            label: label,
            description: "",
            source: "",
            allergy: "",
            version: 0,
            currency: "",
            visitMinutes: 0,
            pinned: false,
            rate: 0.0,
            status: ResultSummaryStatus.draft
        )
    }
}
