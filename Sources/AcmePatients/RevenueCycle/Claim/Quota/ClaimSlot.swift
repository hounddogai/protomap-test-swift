import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim slot is in its life cycle.
    enum ClaimSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A claim slot. Its code is unique within a tenant.
    final class ClaimSlot {
        var code: String
        var label: String
        var windowDays: Int
        var updatedAt: Int
        var timezone: String
        var status: ClaimSlotStatus

        init(code: String, label: String, windowDays: Int, updatedAt: Int, timezone: String, status: ClaimSlotStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.updatedAt = updatedAt
            self.timezone = timezone
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

        func canMoveTo(_ next: ClaimSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == ClaimSlotStatus.queued || next == ClaimSlotStatus.running
            case .queued:
                return next == ClaimSlotStatus.done || next == ClaimSlotStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ClaimSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return (Double(windowDays) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> ClaimSlot {
            return ClaimSlot(
                code: code,
                label: label,
                windowDays: windowDays,
                updatedAt: updatedAt,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a claim slot in status new.
    static func newClaimSlot(_ code: String, label: String) -> ClaimSlot {
        return ClaimSlot(
            code: code,
            label: label,
            windowDays: 0,
            updatedAt: 0,
            timezone: "",
            status: ClaimSlotStatus.new
        )
    }
}
