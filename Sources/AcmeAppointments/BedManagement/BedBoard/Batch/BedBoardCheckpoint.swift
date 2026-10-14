import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board checkpoint is in its life cycle.
    enum BedBoardCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a bed board checkpoint and its current status.
    final class BedBoardCheckpoint {
        var code: String
        var title: String
        var pinned: Bool
        var segment: String
        var specialty: String
        var quantity: Int
        var status: BedBoardCheckpointStatus

        init(code: String, title: String, pinned: Bool, segment: String, specialty: String, quantity: Int, status: BedBoardCheckpointStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.segment = segment
            self.specialty = specialty
            self.quantity = quantity
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

        func canMoveTo(_ next: BedBoardCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
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
                return next == BedBoardCheckpointStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> BedBoardCheckpoint {
            return BedBoardCheckpoint(
                code: code,
                title: title,
                pinned: pinned,
                segment: segment,
                specialty: specialty,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a bed board checkpoint in status requested.
    static func newBedBoardCheckpoint(_ code: String, title: String) -> BedBoardCheckpoint {
        return BedBoardCheckpoint(
            code: code,
            title: title,
            pinned: false,
            segment: "",
            specialty: "",
            quantity: 0,
            status: BedBoardCheckpointStatus.requested
        )
    }
}
