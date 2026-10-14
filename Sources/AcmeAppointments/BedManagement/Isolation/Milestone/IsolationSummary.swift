import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation summary is in its life cycle.
    enum IsolationSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A isolation summary. Its code is unique within a tenant.
    final class IsolationSummary {
        var code: String
        var label: String
        var visible: Bool
        var visitMinutes: Int
        var facility: String
        var discount: Double
        var currency: String
        var description: String
        var status: IsolationSummaryStatus

        init(code: String, label: String, visible: Bool, visitMinutes: Int, facility: String, discount: Double, currency: String, description: String, status: IsolationSummaryStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.visitMinutes = visitMinutes
            self.facility = facility
            self.discount = discount
            self.currency = currency
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationSummaryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == IsolationSummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return (discount * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> IsolationSummary {
            return IsolationSummary(
                code: code,
                label: label,
                visible: visible,
                visitMinutes: visitMinutes,
                facility: facility,
                discount: discount,
                currency: currency,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a isolation summary in status idle.
    static func newIsolationSummary(_ code: String, label: String) -> IsolationSummary {
        return IsolationSummary(
            code: code,
            label: label,
            visible: false,
            visitMinutes: 0,
            facility: "",
            discount: 0.0,
            currency: "",
            description: "",
            status: IsolationSummaryStatus.idle
        )
    }
}
