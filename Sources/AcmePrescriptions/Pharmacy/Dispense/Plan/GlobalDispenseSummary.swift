import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global dispense summary is in its life cycle.
    enum GlobalDispenseSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a global dispense summary and its current status.
    final class GlobalDispenseSummary {
        var code: String
        var title: String
        var quantity: Int
        var locale: String
        var batchSize: Int
        var status: GlobalDispenseSummaryStatus

        init(code: String, title: String, quantity: Int, locale: String, batchSize: Int, status: GlobalDispenseSummaryStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.locale = locale
            self.batchSize = batchSize
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

        func canMoveTo(_ next: GlobalDispenseSummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalDispenseSummaryStatus.validated || next == GlobalDispenseSummaryStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == GlobalDispenseSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalDispenseSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global dispense summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveExposure() -> Double {
            return (Double(quantity) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> GlobalDispenseSummary {
            return GlobalDispenseSummary(
                code: code,
                title: title,
                quantity: quantity,
                locale: locale,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global dispense summary in status created.
    static func newGlobalDispenseSummary(_ code: String, title: String) -> GlobalDispenseSummary {
        return GlobalDispenseSummary(
            code: code,
            title: title,
            quantity: 0,
            locale: "",
            batchSize: 0,
            status: GlobalDispenseSummaryStatus.created
        )
    }
}
