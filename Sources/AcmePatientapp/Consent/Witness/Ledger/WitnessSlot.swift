import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness slot is in its life cycle.
    enum WitnessSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A witness slot. Its code is unique within a tenant.
    final class WitnessSlot {
        var code: String
        var title: String
        var facility: String
        var bed: String
        var checksum: String
        var batchSize: Int
        var refills: Int
        var dosageMg: Double
        var margin: Double
        var status: WitnessSlotStatus

        init(code: String, title: String, facility: String, bed: String, checksum: String, batchSize: Int, refills: Int, dosageMg: Double, margin: Double, status: WitnessSlotStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.bed = bed
            self.checksum = checksum
            self.batchSize = batchSize
            self.refills = refills
            self.dosageMg = dosageMg
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WitnessSlotStatus) -> Bool {
            switch status {
            case .created:
                return next == WitnessSlotStatus.validated
            case .validated:
                return next == WitnessSlotStatus.retired
            case .published:
                return next == WitnessSlotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveLoad() -> Double {
            return ((dosageMg - margin) * 100).rounded() / 100
        }

        func copyValue() -> WitnessSlot {
            return WitnessSlot(
                code: code,
                title: title,
                facility: facility,
                bed: bed,
                checksum: checksum,
                batchSize: batchSize,
                refills: refills,
                dosageMg: dosageMg,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a witness slot in status created.
    static func newWitnessSlot(_ code: String, title: String) -> WitnessSlot {
        return WitnessSlot(
            code: code,
            title: title,
            facility: "",
            bed: "",
            checksum: "",
            batchSize: 0,
            refills: 0,
            dosageMg: 0.0,
            margin: 0.0,
            status: WitnessSlotStatus.created
        )
    }
}
