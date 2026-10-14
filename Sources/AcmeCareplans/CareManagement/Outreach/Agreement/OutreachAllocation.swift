import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach allocation is in its life cycle.
    enum OutreachAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A outreach allocation. Its code is unique within a tenant.
    final class OutreachAllocation {
        var code: String
        var label: String
        var windowDays: Int
        var acuity: Int
        var priority: Int
        var pinned: Bool
        var category: String
        var minimum: Double
        var patientRef: String
        var currency: String
        var status: OutreachAllocationStatus

        init(code: String, label: String, windowDays: Int, acuity: Int, priority: Int, pinned: Bool, category: String, minimum: Double, patientRef: String, currency: String, status: OutreachAllocationStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.acuity = acuity
            self.priority = priority
            self.pinned = pinned
            self.category = category
            self.minimum = minimum
            self.patientRef = patientRef
            self.currency = currency
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

        func canMoveTo(_ next: OutreachAllocationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == OutreachAllocationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedTotal() -> Double {
            return (Double(windowDays) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> OutreachAllocation {
            return OutreachAllocation(
                code: code,
                label: label,
                windowDays: windowDays,
                acuity: acuity,
                priority: priority,
                pinned: pinned,
                category: category,
                minimum: minimum,
                patientRef: patientRef,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a outreach allocation in status new.
    static func newOutreachAllocation(_ code: String, label: String) -> OutreachAllocation {
        return OutreachAllocation(
            code: code,
            label: label,
            windowDays: 0,
            acuity: 0,
            priority: 0,
            pinned: false,
            category: "",
            minimum: 0.0,
            patientRef: "",
            currency: "",
            status: OutreachAllocationStatus.new
        )
    }
}
