import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap tier is in its life cycle.
    enum CareGapTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One care gap tier, with what the planners need to act on it.
    final class CareGapTier {
        var code: String
        var label: String
        var facility: String
        var summary: String
        var quantity: Int
        var source: String
        var status: CareGapTierStatus

        init(code: String, label: String, facility: String, summary: String, quantity: Int, source: String, status: CareGapTierStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.summary = summary
            self.quantity = quantity
            self.source = source
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

        func canMoveTo(_ next: CareGapTierStatus) -> Bool {
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
                return next == CareGapTierStatus.revoked || next == CareGapTierStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CareGapTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> CareGapTier {
            return CareGapTier(
                code: code,
                label: label,
                facility: facility,
                summary: summary,
                quantity: quantity,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a care gap tier in status requested.
    static func newCareGapTier(_ code: String, label: String) -> CareGapTier {
        return CareGapTier(
            code: code,
            label: label,
            facility: "",
            summary: "",
            quantity: 0,
            source: "",
            status: CareGapTierStatus.requested
        )
    }
}
