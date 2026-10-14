import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback assessment allocation is in its life cycle.
    enum FallbackAssessmentAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback assessment allocation as the assessment team keeps it.
    final class FallbackAssessmentAllocation {
        var code: String
        var name: String
        var description: String
        var region: String
        var floorValue: Double
        var visible: Bool
        var quantity: Int
        var discount: Double
        var status: FallbackAssessmentAllocationStatus

        init(code: String, name: String, description: String, region: String, floorValue: Double, visible: Bool, quantity: Int, discount: Double, status: FallbackAssessmentAllocationStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.region = region
            self.floorValue = floorValue
            self.visible = visible
            self.quantity = quantity
            self.discount = discount
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

        func canMoveTo(_ next: FallbackAssessmentAllocationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackAssessmentAllocationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackAssessmentAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback assessment allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback assessment allocation") \(code)"
        }

        func projectedTotal() -> Double {
            return ((floorValue - discount) * 100).rounded() / 100
        }

        func copyValue() -> FallbackAssessmentAllocation {
            return FallbackAssessmentAllocation(
                code: code,
                name: name,
                description: description,
                region: region,
                floorValue: floorValue,
                visible: visible,
                quantity: quantity,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback assessment allocation in status requested.
    static func newFallbackAssessmentAllocation(_ code: String, name: String) -> FallbackAssessmentAllocation {
        return FallbackAssessmentAllocation(
            code: code,
            name: name,
            description: "",
            region: "",
            floorValue: 0.0,
            visible: false,
            quantity: 0,
            discount: 0.0,
            status: FallbackAssessmentAllocationStatus.requested
        )
    }
}
