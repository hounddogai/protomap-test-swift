import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff record is in its life cycle.
    enum HandoffRecordStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A handoff record as the handoff team keeps it.
    final class HandoffRecord {
        var code: String
        var title: String
        var approved: Bool
        var cost: Double
        var specialty: String
        var facility: String
        var durationMinutes: Int
        var status: HandoffRecordStatus

        init(code: String, title: String, approved: Bool, cost: Double, specialty: String, facility: String, durationMinutes: Int, status: HandoffRecordStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.cost = cost
            self.specialty = specialty
            self.facility = facility
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: HandoffRecordStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == HandoffRecordStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedVolume() -> Double {
            return (Double(durationMinutes) * cost * 100).rounded() / 100
        }

        func copyValue() -> HandoffRecord {
            return HandoffRecord(
                code: code,
                title: title,
                approved: approved,
                cost: cost,
                specialty: specialty,
                facility: facility,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a handoff record in status created.
    static func newHandoffRecord(_ code: String, title: String) -> HandoffRecord {
        return HandoffRecord(
            code: code,
            title: title,
            approved: false,
            cost: 0.0,
            specialty: "",
            facility: "",
            durationMinutes: 0,
            status: HandoffRecordStatus.created
        )
    }
}
