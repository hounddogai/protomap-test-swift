import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board target is in its life cycle.
    enum BedBoardTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A bed board target. Its code is unique within a tenant.
    final class BedBoardTarget {
        var code: String
        var label: String
        var acuity: Int
        var archived: Bool
        var active: Bool
        var facility: String
        var channel: String
        var weight: Double
        var status: BedBoardTargetStatus

        init(code: String, label: String, acuity: Int, archived: Bool, active: Bool, facility: String, channel: String, weight: Double, status: BedBoardTargetStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.archived = archived
            self.active = active
            self.facility = facility
            self.channel = channel
            self.weight = weight
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

        func canMoveTo(_ next: BedBoardTargetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BedBoardTargetStatus.approved
            case .approved:
                return next == BedBoardTargetStatus.rejected
            case .rejected:
                return next == BedBoardTargetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedTotal() -> Double {
            return (Double(acuity) * weight * 100).rounded() / 100
        }

        func copyValue() -> BedBoardTarget {
            return BedBoardTarget(
                code: code,
                label: label,
                acuity: acuity,
                archived: archived,
                active: active,
                facility: facility,
                channel: channel,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a bed board target in status proposed.
    static func newBedBoardTarget(_ code: String, label: String) -> BedBoardTarget {
        return BedBoardTarget(
            code: code,
            label: label,
            acuity: 0,
            archived: false,
            active: false,
            facility: "",
            channel: "",
            weight: 0.0,
            status: BedBoardTargetStatus.proposed
        )
    }
}
