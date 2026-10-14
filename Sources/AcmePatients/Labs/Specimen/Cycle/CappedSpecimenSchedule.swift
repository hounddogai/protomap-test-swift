import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped specimen schedule is in its life cycle.
    enum CappedSpecimenScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a capped specimen schedule and its current status.
    final class CappedSpecimenSchedule {
        var code: String
        var name: String
        var visitMinutes: Int
        var attributes: [String: String]
        var facility: String
        var status: CappedSpecimenScheduleStatus

        init(code: String, name: String, visitMinutes: Int, attributes: [String: String], facility: String, status: CappedSpecimenScheduleStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.attributes = attributes
            self.facility = facility
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

        func canMoveTo(_ next: CappedSpecimenScheduleStatus) -> Bool {
            switch status {
            case .idle:
                return next == CappedSpecimenScheduleStatus.warming
            case .warming:
                return next == CappedSpecimenScheduleStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedSpecimenScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped specimen schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> CappedSpecimenSchedule {
            return CappedSpecimenSchedule(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                attributes: attributes,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a capped specimen schedule in status idle.
    static func newCappedSpecimenSchedule(_ code: String, name: String) -> CappedSpecimenSchedule {
        return CappedSpecimenSchedule(
            code: code,
            name: name,
            visitMinutes: 0,
            attributes: [:],
            facility: "",
            status: CappedSpecimenScheduleStatus.idle
        )
    }
}
