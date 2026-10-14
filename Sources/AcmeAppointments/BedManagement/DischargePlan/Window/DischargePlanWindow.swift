import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan window is in its life cycle.
    enum DischargePlanWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a discharge plan window and its current status.
    final class DischargePlanWindow {
        var code: String
        var name: String
        var checksum: String
        var acuity: Int
        var archived: Bool
        var description: String
        var status: DischargePlanWindowStatus

        init(code: String, name: String, checksum: String, acuity: Int, archived: Bool, description: String, status: DischargePlanWindowStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.acuity = acuity
            self.archived = archived
            self.description = description
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

        func canMoveTo(_ next: DischargePlanWindowStatus) -> Bool {
            switch status {
            case .idle:
                return next == DischargePlanWindowStatus.warming || next == DischargePlanWindowStatus.ready
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DischargePlanWindowStatus.draining || next == DischargePlanWindowStatus.stopped
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

        func moveTo(_ next: DischargePlanWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("discharge plan window") \(code)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> DischargePlanWindow {
            return DischargePlanWindow(
                code: code,
                name: name,
                checksum: checksum,
                acuity: acuity,
                archived: archived,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a discharge plan window in status idle.
    static func newDischargePlanWindow(_ code: String, name: String) -> DischargePlanWindow {
        return DischargePlanWindow(
            code: code,
            name: name,
            checksum: "",
            acuity: 0,
            archived: false,
            description: "",
            status: DischargePlanWindowStatus.idle
        )
    }
}
