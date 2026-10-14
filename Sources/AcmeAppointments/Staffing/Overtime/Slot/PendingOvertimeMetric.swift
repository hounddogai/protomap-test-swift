import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending overtime metric is in its life cycle.
    enum PendingOvertimeMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a pending overtime metric and its current status.
    final class PendingOvertimeMetric {
        var code: String
        var name: String
        var payer: String
        var acuity: Int
        var pinned: Bool
        var capacity: Int
        var label: String
        var visitMinutes: Int
        var status: PendingOvertimeMetricStatus

        init(code: String, name: String, payer: String, acuity: Int, pinned: Bool, capacity: Int, label: String, visitMinutes: Int, status: PendingOvertimeMetricStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.acuity = acuity
            self.pinned = pinned
            self.capacity = capacity
            self.label = label
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: PendingOvertimeMetricStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingOvertimeMetricStatus.reopened || next == PendingOvertimeMetricStatus.archived
            case .inReview:
                return next == PendingOvertimeMetricStatus.resolved || next == PendingOvertimeMetricStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: PendingOvertimeMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending overtime metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func adjustedTotal() -> Double {
            return ((Double(visitMinutes) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingOvertimeMetric {
            return PendingOvertimeMetric(
                code: code,
                name: name,
                payer: payer,
                acuity: acuity,
                pinned: pinned,
                capacity: capacity,
                label: label,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending overtime metric in status open.
    static func newPendingOvertimeMetric(_ code: String, name: String) -> PendingOvertimeMetric {
        return PendingOvertimeMetric(
            code: code,
            name: name,
            payer: "",
            acuity: 0,
            pinned: false,
            capacity: 0,
            label: "",
            visitMinutes: 0,
            status: PendingOvertimeMetricStatus.`open`
        )
    }
}
