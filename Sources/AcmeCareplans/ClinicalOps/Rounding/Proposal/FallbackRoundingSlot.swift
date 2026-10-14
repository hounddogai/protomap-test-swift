import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback rounding slot is in its life cycle.
    enum FallbackRoundingSlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback rounding slot. Its code is unique within a tenant.
    final class FallbackRoundingSlot {
        var code: String
        var name: String
        var active: Bool
        var margin: Double
        var discount: Double
        var patientRef: String
        var limit: Int
        var checksum: String
        var ceiling: Double
        var status: FallbackRoundingSlotStatus

        init(code: String, name: String, active: Bool, margin: Double, discount: Double, patientRef: String, limit: Int, checksum: String, ceiling: Double, status: FallbackRoundingSlotStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.margin = margin
            self.discount = discount
            self.patientRef = patientRef
            self.limit = limit
            self.checksum = checksum
            self.ceiling = ceiling
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

        func canMoveTo(_ next: FallbackRoundingSlotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: FallbackRoundingSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback rounding slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback rounding slot") \(code)"
        }

        func netValue() -> Double {
            return ((Double(limit) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRoundingSlot {
            return FallbackRoundingSlot(
                code: code,
                name: name,
                active: active,
                margin: margin,
                discount: discount,
                patientRef: patientRef,
                limit: limit,
                checksum: checksum,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback rounding slot in status proposed.
    static func newFallbackRoundingSlot(_ code: String, name: String) -> FallbackRoundingSlot {
        return FallbackRoundingSlot(
            code: code,
            name: name,
            active: false,
            margin: 0.0,
            discount: 0.0,
            patientRef: "",
            limit: 0,
            checksum: "",
            ceiling: 0.0,
            status: FallbackRoundingSlotStatus.proposed
        )
    }
}
