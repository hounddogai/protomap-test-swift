import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient care protocol claim is in its life cycle.
    enum LenientCareProtocolClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A lenient care protocol claim as the care protocol team keeps it.
    final class LenientCareProtocolClaim {
        var code: String
        var label: String
        var quantity: Int
        var durationMinutes: Int
        var graceDays: Int
        var status: LenientCareProtocolClaimStatus

        init(code: String, label: String, quantity: Int, durationMinutes: Int, graceDays: Int, status: LenientCareProtocolClaimStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.graceDays = graceDays
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

        func canMoveTo(_ next: LenientCareProtocolClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientCareProtocolClaimStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LenientCareProtocolClaimStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientCareProtocolClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient care protocol claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return ((Double(durationMinutes) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientCareProtocolClaim {
            return LenientCareProtocolClaim(
                code: code,
                label: label,
                quantity: quantity,
                durationMinutes: durationMinutes,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient care protocol claim in status new.
    static func newLenientCareProtocolClaim(_ code: String, label: String) -> LenientCareProtocolClaim {
        return LenientCareProtocolClaim(
            code: code,
            label: label,
            quantity: 0,
            durationMinutes: 0,
            graceDays: 0,
            status: LenientCareProtocolClaimStatus.new
        )
    }
}
