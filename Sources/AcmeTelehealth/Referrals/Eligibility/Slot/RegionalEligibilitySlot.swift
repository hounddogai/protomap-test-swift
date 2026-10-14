import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional eligibility slot is in its life cycle.
    enum RegionalEligibilitySlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A regional eligibility slot as the eligibility team keeps it.
    final class RegionalEligibilitySlot {
        var code: String
        var label: String
        var windowDays: Int
        var approved: Bool
        var summary: String
        var margin: Double
        var status: RegionalEligibilitySlotStatus

        init(code: String, label: String, windowDays: Int, approved: Bool, summary: String, margin: Double, status: RegionalEligibilitySlotStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.approved = approved
            self.summary = summary
            self.margin = margin
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

        func canMoveTo(_ next: RegionalEligibilitySlotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RegionalEligibilitySlotStatus.ready || next == RegionalEligibilitySlotStatus.stopped
            case .ready:
                return next == RegionalEligibilitySlotStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RegionalEligibilitySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional eligibility slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional eligibility slot") \(code)"
        }

        func adjustedExposure() -> Double {
            return (margin * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> RegionalEligibilitySlot {
            return RegionalEligibilitySlot(
                code: code,
                label: label,
                windowDays: windowDays,
                approved: approved,
                summary: summary,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional eligibility slot in status idle.
    static func newRegionalEligibilitySlot(_ code: String, label: String) -> RegionalEligibilitySlot {
        return RegionalEligibilitySlot(
            code: code,
            label: label,
            windowDays: 0,
            approved: false,
            summary: "",
            margin: 0.0,
            status: RegionalEligibilitySlotStatus.idle
        )
    }
}
