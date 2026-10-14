import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback charge slot is in its life cycle.
    enum FallbackChargeSlotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a fallback charge slot and its current status.
    final class FallbackChargeSlot {
        var code: String
        var label: String
        var limit: Int
        var startsAt: Int
        var diagnosisCode: String
        var summary: String
        var status: FallbackChargeSlotStatus

        init(code: String, label: String, limit: Int, startsAt: Int, diagnosisCode: String, summary: String, status: FallbackChargeSlotStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackChargeSlotStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == FallbackChargeSlotStatus.revoked
            case .revoked:
                return next == FallbackChargeSlotStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackChargeSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback charge slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(startsAt) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackChargeSlot {
            return FallbackChargeSlot(
                code: code,
                label: label,
                limit: limit,
                startsAt: startsAt,
                diagnosisCode: diagnosisCode,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback charge slot in status requested.
    static func newFallbackChargeSlot(_ code: String, label: String) -> FallbackChargeSlot {
        return FallbackChargeSlot(
            code: code,
            label: label,
            limit: 0,
            startsAt: 0,
            diagnosisCode: "",
            summary: "",
            status: FallbackChargeSlotStatus.requested
        )
    }
}
