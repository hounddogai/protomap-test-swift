import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary slot snapshot is in its life cycle.
    enum PrimarySlotSnapshotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A primary slot snapshot as the slot team keeps it.
    final class PrimarySlotSnapshot {
        var code: String
        var name: String
        var externalRef: String
        var unit: String
        var acuity: Int
        var quantity: Int
        var category: String
        var status: PrimarySlotSnapshotStatus

        init(code: String, name: String, externalRef: String, unit: String, acuity: Int, quantity: Int, category: String, status: PrimarySlotSnapshotStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.unit = unit
            self.acuity = acuity
            self.quantity = quantity
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimarySlotSnapshotStatus) -> Bool {
            switch status {
            case .idle:
                return next == PrimarySlotSnapshotStatus.ready
            case .warming:
                return next == PrimarySlotSnapshotStatus.ready || next == PrimarySlotSnapshotStatus.draining
            case .ready:
                return next == PrimarySlotSnapshotStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PrimarySlotSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary slot snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary slot snapshot") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(quantity) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySlotSnapshot {
            return PrimarySlotSnapshot(
                code: code,
                name: name,
                externalRef: externalRef,
                unit: unit,
                acuity: acuity,
                quantity: quantity,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary slot snapshot in status idle.
    static func newPrimarySlotSnapshot(_ code: String, name: String) -> PrimarySlotSnapshot {
        return PrimarySlotSnapshot(
            code: code,
            name: name,
            externalRef: "",
            unit: "",
            acuity: 0,
            quantity: 0,
            category: "",
            status: PrimarySlotSnapshotStatus.idle
        )
    }
}
