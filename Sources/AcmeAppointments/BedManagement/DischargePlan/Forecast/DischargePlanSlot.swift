import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan slot is in its life cycle.
    enum DischargePlanSlotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a discharge plan slot and its current status.
    final class DischargePlanSlot {
        var code: String
        var name: String
        var checksum: String
        var ceiling: Double
        var currency: String
        var batchSize: Int
        var externalRef: String
        var title: String
        var status: DischargePlanSlotStatus

        init(code: String, name: String, checksum: String, ceiling: Double, currency: String, batchSize: Int, externalRef: String, title: String, status: DischargePlanSlotStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.ceiling = ceiling
            self.currency = currency
            self.batchSize = batchSize
            self.externalRef = externalRef
            self.title = title
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

        func canMoveTo(_ next: DischargePlanSlotStatus) -> Bool {
            switch status {
            case .requested:
                return next == DischargePlanSlotStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DischargePlanSlotStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return ((ceiling - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanSlot {
            return DischargePlanSlot(
                code: code,
                name: name,
                checksum: checksum,
                ceiling: ceiling,
                currency: currency,
                batchSize: batchSize,
                externalRef: externalRef,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a discharge plan slot in status requested.
    static func newDischargePlanSlot(_ code: String, name: String) -> DischargePlanSlot {
        return DischargePlanSlot(
            code: code,
            name: name,
            checksum: "",
            ceiling: 0.0,
            currency: "",
            batchSize: 0,
            externalRef: "",
            title: "",
            status: DischargePlanSlotStatus.requested
        )
    }
}
