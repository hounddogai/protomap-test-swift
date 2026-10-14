import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive follow up mapping is in its life cycle.
    enum AdaptiveFollowUpMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive follow up mapping as the follow up team keeps it.
    final class AdaptiveFollowUpMapping {
        var code: String
        var label: String
        var approved: Bool
        var capacity: Int
        var ceiling: Double
        var windowDays: Int
        var refills: Int
        var discount: Double
        var durationMinutes: Int
        var status: AdaptiveFollowUpMappingStatus

        init(code: String, label: String, approved: Bool, capacity: Int, ceiling: Double, windowDays: Int, refills: Int, discount: Double, durationMinutes: Int, status: AdaptiveFollowUpMappingStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.capacity = capacity
            self.ceiling = ceiling
            self.windowDays = windowDays
            self.refills = refills
            self.discount = discount
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: AdaptiveFollowUpMappingStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AdaptiveFollowUpMappingStatus.running
            case .running:
                return next == AdaptiveFollowUpMappingStatus.done
            case .done:
                return next == AdaptiveFollowUpMappingStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveFollowUpMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive follow up mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedValue() -> Double {
            return ((Double(refills) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveFollowUpMapping {
            return AdaptiveFollowUpMapping(
                code: code,
                label: label,
                approved: approved,
                capacity: capacity,
                ceiling: ceiling,
                windowDays: windowDays,
                refills: refills,
                discount: discount,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive follow up mapping in status new.
    static func newAdaptiveFollowUpMapping(_ code: String, label: String) -> AdaptiveFollowUpMapping {
        return AdaptiveFollowUpMapping(
            code: code,
            label: label,
            approved: false,
            capacity: 0,
            ceiling: 0.0,
            windowDays: 0,
            refills: 0,
            discount: 0.0,
            durationMinutes: 0,
            status: AdaptiveFollowUpMappingStatus.new
        )
    }
}
