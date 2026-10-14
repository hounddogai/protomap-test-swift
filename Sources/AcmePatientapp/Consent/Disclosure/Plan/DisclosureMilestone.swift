import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure milestone is in its life cycle.
    enum DisclosureMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A disclosure milestone as the disclosure team keeps it.
    final class DisclosureMilestone {
        var code: String
        var label: String
        var acuity: Int
        var revision: Int
        var visitMinutes: Int
        var capacity: Int
        var margin: Double
        var locale: String
        var status: DisclosureMilestoneStatus

        init(code: String, label: String, acuity: Int, revision: Int, visitMinutes: Int, capacity: Int, margin: Double, locale: String, status: DisclosureMilestoneStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.revision = revision
            self.visitMinutes = visitMinutes
            self.capacity = capacity
            self.margin = margin
            self.locale = locale
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

        func canMoveTo(_ next: DisclosureMilestoneStatus) -> Bool {
            switch status {
            case .new:
                return next == DisclosureMilestoneStatus.queued || next == DisclosureMilestoneStatus.done
            case .queued:
                return next == DisclosureMilestoneStatus.failed
            case .running:
                return next == DisclosureMilestoneStatus.done || next == DisclosureMilestoneStatus.failed
            case .done:
                return next == DisclosureMilestoneStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveValue() -> Double {
            return ((margin - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureMilestone {
            return DisclosureMilestone(
                code: code,
                label: label,
                acuity: acuity,
                revision: revision,
                visitMinutes: visitMinutes,
                capacity: capacity,
                margin: margin,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a disclosure milestone in status new.
    static func newDisclosureMilestone(_ code: String, label: String) -> DisclosureMilestone {
        return DisclosureMilestone(
            code: code,
            label: label,
            acuity: 0,
            revision: 0,
            visitMinutes: 0,
            capacity: 0,
            margin: 0.0,
            locale: "",
            status: DisclosureMilestoneStatus.new
        )
    }
}
