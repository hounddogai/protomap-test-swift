import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession checkpoint is in its life cycle.
    enum AccessionCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A accession checkpoint. Its code is unique within a tenant.
    final class AccessionCheckpoint {
        var code: String
        var label: String
        var allergy: String
        var floorValue: Double
        var quantity: Int
        var ceiling: Double
        var status: AccessionCheckpointStatus

        init(code: String, label: String, allergy: String, floorValue: Double, quantity: Int, ceiling: Double, status: AccessionCheckpointStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.floorValue = floorValue
            self.quantity = quantity
            self.ceiling = ceiling
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

        func canMoveTo(_ next: AccessionCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                return next == AccessionCheckpointStatus.granted || next == AccessionCheckpointStatus.expired
            case .granted:
                switch next {
                case .expired:
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

        func moveTo(_ next: AccessionCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedExposure() -> Double {
            return ((ceiling - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> AccessionCheckpoint {
            return AccessionCheckpoint(
                code: code,
                label: label,
                allergy: allergy,
                floorValue: floorValue,
                quantity: quantity,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a accession checkpoint in status requested.
    static func newAccessionCheckpoint(_ code: String, label: String) -> AccessionCheckpoint {
        return AccessionCheckpoint(
            code: code,
            label: label,
            allergy: "",
            floorValue: 0.0,
            quantity: 0,
            ceiling: 0.0,
            status: AccessionCheckpointStatus.requested
        )
    }
}
