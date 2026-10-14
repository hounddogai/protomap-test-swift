import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched bed board slot is in its life cycle.
    enum BatchedBedBoardSlotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a batched bed board slot and its current status.
    final class BatchedBedBoardSlot {
        var code: String
        var title: String
        var bed: String
        var refills: Int
        var checksum: String
        var active: Bool
        var revision: Int
        var discount: Double
        var externalRef: String
        var endsAt: Int
        var status: BatchedBedBoardSlotStatus

        init(code: String, title: String, bed: String, refills: Int, checksum: String, active: Bool, revision: Int, discount: Double, externalRef: String, endsAt: Int, status: BatchedBedBoardSlotStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.refills = refills
            self.checksum = checksum
            self.active = active
            self.revision = revision
            self.discount = discount
            self.externalRef = externalRef
            self.endsAt = endsAt
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

        func canMoveTo(_ next: BatchedBedBoardSlotStatus) -> Bool {
            switch status {
            case .requested:
                return next == BatchedBedBoardSlotStatus.granted || next == BatchedBedBoardSlotStatus.expired
            case .granted:
                return next == BatchedBedBoardSlotStatus.revoked || next == BatchedBedBoardSlotStatus.expired
            case .revoked:
                return next == BatchedBedBoardSlotStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedBedBoardSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched bed board slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedLoad() -> Double {
            return ((Double(revision) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedBedBoardSlot {
            return BatchedBedBoardSlot(
                code: code,
                title: title,
                bed: bed,
                refills: refills,
                checksum: checksum,
                active: active,
                revision: revision,
                discount: discount,
                externalRef: externalRef,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched bed board slot in status requested.
    static func newBatchedBedBoardSlot(_ code: String, title: String) -> BatchedBedBoardSlot {
        return BatchedBedBoardSlot(
            code: code,
            title: title,
            bed: "",
            refills: 0,
            checksum: "",
            active: false,
            revision: 0,
            discount: 0.0,
            externalRef: "",
            endsAt: 0,
            status: BatchedBedBoardSlotStatus.requested
        )
    }
}
