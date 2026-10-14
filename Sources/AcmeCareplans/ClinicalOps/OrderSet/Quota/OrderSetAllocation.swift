import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set allocation is in its life cycle.
    enum OrderSetAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a order set allocation and its current status.
    final class OrderSetAllocation {
        var code: String
        var label: String
        var floorValue: Double
        var quantity: Int
        var source: String
        var checksum: String
        var status: OrderSetAllocationStatus

        init(code: String, label: String, floorValue: Double, quantity: Int, source: String, checksum: String, status: OrderSetAllocationStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.quantity = quantity
            self.source = source
            self.checksum = checksum
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

        func canMoveTo(_ next: OrderSetAllocationStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
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

        func moveTo(_ next: OrderSetAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("order set allocation") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(quantity) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> OrderSetAllocation {
            return OrderSetAllocation(
                code: code,
                label: label,
                floorValue: floorValue,
                quantity: quantity,
                source: source,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a order set allocation in status requested.
    static func newOrderSetAllocation(_ code: String, label: String) -> OrderSetAllocation {
        return OrderSetAllocation(
            code: code,
            label: label,
            floorValue: 0.0,
            quantity: 0,
            source: "",
            checksum: "",
            status: OrderSetAllocationStatus.requested
        )
    }
}
