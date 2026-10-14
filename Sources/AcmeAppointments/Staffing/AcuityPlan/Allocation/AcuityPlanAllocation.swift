import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan allocation is in its life cycle.
    enum AcuityPlanAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A acuity plan allocation as the acuity plan team keeps it.
    final class AcuityPlanAllocation {
        var code: String
        var title: String
        var floorValue: Double
        var quantity: Int
        var procedureCode: String
        var priority: Int
        var refills: Int
        var copay: Double
        var windowDays: Int
        var region: String
        var status: AcuityPlanAllocationStatus

        init(code: String, title: String, floorValue: Double, quantity: Int, procedureCode: String, priority: Int, refills: Int, copay: Double, windowDays: Int, region: String, status: AcuityPlanAllocationStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.quantity = quantity
            self.procedureCode = procedureCode
            self.priority = priority
            self.refills = refills
            self.copay = copay
            self.windowDays = windowDays
            self.region = region
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

        func canMoveTo(_ next: AcuityPlanAllocationStatus) -> Bool {
            switch status {
            case .requested:
                return next == AcuityPlanAllocationStatus.granted || next == AcuityPlanAllocationStatus.revoked
            case .granted:
                return next == AcuityPlanAllocationStatus.revoked || next == AcuityPlanAllocationStatus.expired
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

        func moveTo(_ next: AcuityPlanAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(quantity) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanAllocation {
            return AcuityPlanAllocation(
                code: code,
                title: title,
                floorValue: floorValue,
                quantity: quantity,
                procedureCode: procedureCode,
                priority: priority,
                refills: refills,
                copay: copay,
                windowDays: windowDays,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a acuity plan allocation in status requested.
    static func newAcuityPlanAllocation(_ code: String, title: String) -> AcuityPlanAllocation {
        return AcuityPlanAllocation(
            code: code,
            title: title,
            floorValue: 0.0,
            quantity: 0,
            procedureCode: "",
            priority: 0,
            refills: 0,
            copay: 0.0,
            windowDays: 0,
            region: "",
            status: AcuityPlanAllocationStatus.requested
        )
    }
}
