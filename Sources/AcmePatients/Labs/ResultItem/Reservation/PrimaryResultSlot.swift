import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary result slot is in its life cycle.
    enum PrimaryResultSlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One primary result slot, with what the planners need to act on it.
    final class PrimaryResultSlot {
        var code: String
        var title: String
        var copay: Double
        var maximum: Double
        var revision: Int
        var threshold: Double
        var name: String
        var phone: String
        var score: Double
        var floorValue: Double
        var pinned: Bool
        var status: PrimaryResultSlotStatus

        init(code: String, title: String, copay: Double, maximum: Double, revision: Int, threshold: Double, name: String, phone: String, score: Double, floorValue: Double, pinned: Bool, status: PrimaryResultSlotStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.maximum = maximum
            self.revision = revision
            self.threshold = threshold
            self.name = name
            self.phone = phone
            self.score = score
            self.floorValue = floorValue
            self.pinned = pinned
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

        func canMoveTo(_ next: PrimaryResultSlotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PrimaryResultSlotStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryResultSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary result slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedTotal() -> Double {
            return (copay * threshold * 100).rounded() / 100
        }

        func copyValue() -> PrimaryResultSlot {
            return PrimaryResultSlot(
                code: code,
                title: title,
                copay: copay,
                maximum: maximum,
                revision: revision,
                threshold: threshold,
                name: name,
                phone: phone,
                score: score,
                floorValue: floorValue,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary result slot in status proposed.
    static func newPrimaryResultSlot(_ code: String, title: String) -> PrimaryResultSlot {
        return PrimaryResultSlot(
            code: code,
            title: title,
            copay: 0.0,
            maximum: 0.0,
            revision: 0,
            threshold: 0.0,
            name: "",
            phone: "",
            score: 0.0,
            floorValue: 0.0,
            pinned: false,
            status: PrimaryResultSlotStatus.proposed
        )
    }
}
