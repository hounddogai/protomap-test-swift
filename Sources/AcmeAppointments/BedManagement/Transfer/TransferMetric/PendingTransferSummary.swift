import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending transfer summary is in its life cycle.
    enum PendingTransferSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a pending transfer summary and its current status.
    final class PendingTransferSummary {
        var code: String
        var label: String
        var rate: Double
        var budget: Double
        var externalRef: String
        var durationMinutes: Int
        var windowDays: Int
        var cost: Double
        var capacity: Int
        var status: PendingTransferSummaryStatus

        init(code: String, label: String, rate: Double, budget: Double, externalRef: String, durationMinutes: Int, windowDays: Int, cost: Double, capacity: Int, status: PendingTransferSummaryStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.budget = budget
            self.externalRef = externalRef
            self.durationMinutes = durationMinutes
            self.windowDays = windowDays
            self.cost = cost
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingTransferSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PendingTransferSummaryStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: PendingTransferSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending transfer summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedLoad() -> Double {
            return ((rate - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> PendingTransferSummary {
            return PendingTransferSummary(
                code: code,
                label: label,
                rate: rate,
                budget: budget,
                externalRef: externalRef,
                durationMinutes: durationMinutes,
                windowDays: windowDays,
                cost: cost,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending transfer summary in status new.
    static func newPendingTransferSummary(_ code: String, label: String) -> PendingTransferSummary {
        return PendingTransferSummary(
            code: code,
            label: label,
            rate: 0.0,
            budget: 0.0,
            externalRef: "",
            durationMinutes: 0,
            windowDays: 0,
            cost: 0.0,
            capacity: 0,
            status: PendingTransferSummaryStatus.new
        )
    }
}
