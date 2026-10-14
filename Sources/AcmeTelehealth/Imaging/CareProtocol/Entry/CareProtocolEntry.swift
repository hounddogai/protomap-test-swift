import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol entry is in its life cycle.
    enum CareProtocolEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A care protocol entry as the care protocol team keeps it.
    final class CareProtocolEntry {
        var code: String
        var name: String
        var acuity: Int
        var ward: String
        var notes: String
        var approved: Bool
        var status: CareProtocolEntryStatus

        init(code: String, name: String, acuity: Int, ward: String, notes: String, approved: Bool, status: CareProtocolEntryStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.ward = ward
            self.notes = notes
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolEntryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CareProtocolEntryStatus.completed || next == CareProtocolEntryStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CareProtocolEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> CareProtocolEntry {
            return CareProtocolEntry(
                code: code,
                name: name,
                acuity: acuity,
                ward: ward,
                notes: notes,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a care protocol entry in status planned.
    static func newCareProtocolEntry(_ code: String, name: String) -> CareProtocolEntry {
        return CareProtocolEntry(
            code: code,
            name: name,
            acuity: 0,
            ward: "",
            notes: "",
            approved: false,
            status: CareProtocolEntryStatus.planned
        )
    }
}
