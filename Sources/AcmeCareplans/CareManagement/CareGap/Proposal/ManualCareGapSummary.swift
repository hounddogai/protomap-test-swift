import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual care gap summary is in its life cycle.
    enum ManualCareGapSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One manual care gap summary, with what the planners need to act on it.
    final class ManualCareGapSummary {
        var code: String
        var name: String
        var summary: String
        var acuity: Int
        var quantity: Int
        var country: String
        var status: ManualCareGapSummaryStatus

        init(code: String, name: String, summary: String, acuity: Int, quantity: Int, country: String, status: ManualCareGapSummaryStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.acuity = acuity
            self.quantity = quantity
            self.country = country
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

        func canMoveTo(_ next: ManualCareGapSummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == ManualCareGapSummaryStatus.validated || next == ManualCareGapSummaryStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ManualCareGapSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care gap summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedValue() -> Double {
            return ((Double(acuity) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ManualCareGapSummary {
            return ManualCareGapSummary(
                code: code,
                name: name,
                summary: summary,
                acuity: acuity,
                quantity: quantity,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual care gap summary in status created.
    static func newManualCareGapSummary(_ code: String, name: String) -> ManualCareGapSummary {
        return ManualCareGapSummary(
            code: code,
            name: name,
            summary: "",
            acuity: 0,
            quantity: 0,
            country: "",
            status: ManualCareGapSummaryStatus.created
        )
    }
}
