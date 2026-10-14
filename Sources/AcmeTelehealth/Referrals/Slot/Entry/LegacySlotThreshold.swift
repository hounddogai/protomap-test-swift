import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy slot threshold is in its life cycle.
    enum LegacySlotThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One legacy slot threshold, with what the planners need to act on it.
    final class LegacySlotThreshold {
        var code: String
        var label: String
        var acuity: Int
        var reviewer: String
        var refills: Int
        var weight: Double
        var status: LegacySlotThresholdStatus

        init(code: String, label: String, acuity: Int, reviewer: String, refills: Int, weight: Double, status: LegacySlotThresholdStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.reviewer = reviewer
            self.refills = refills
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacySlotThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LegacySlotThresholdStatus.rejected || next == LegacySlotThresholdStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LegacySlotThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy slot threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy slot threshold") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(refills) - weight) * 100).rounded() / 100
        }

        func copyValue() -> LegacySlotThreshold {
            return LegacySlotThreshold(
                code: code,
                label: label,
                acuity: acuity,
                reviewer: reviewer,
                refills: refills,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy slot threshold in status proposed.
    static func newLegacySlotThreshold(_ code: String, label: String) -> LegacySlotThreshold {
        return LegacySlotThreshold(
            code: code,
            label: label,
            acuity: 0,
            reviewer: "",
            refills: 0,
            weight: 0.0,
            status: LegacySlotThresholdStatus.proposed
        )
    }
}
