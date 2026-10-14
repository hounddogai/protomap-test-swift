import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime entry is in its life cycle.
    enum OvertimeEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A overtime entry as the overtime team keeps it.
    final class OvertimeEntry {
        var code: String
        var name: String
        var procedureCode: String
        var attempts: Int
        var allergy: String
        var locale: String
        var acuity: Int
        var status: OvertimeEntryStatus

        init(code: String, name: String, procedureCode: String, attempts: Int, allergy: String, locale: String, acuity: Int, status: OvertimeEntryStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.attempts = attempts
            self.allergy = allergy
            self.locale = locale
            self.acuity = acuity
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

        func canMoveTo(_ next: OvertimeEntryStatus) -> Bool {
            switch status {
            case .idle:
                return next == OvertimeEntryStatus.draining
            case .warming:
                return next == OvertimeEntryStatus.ready
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == OvertimeEntryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedValue() -> Double {
            return (Double(attempts) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeEntry {
            return OvertimeEntry(
                code: code,
                name: name,
                procedureCode: procedureCode,
                attempts: attempts,
                allergy: allergy,
                locale: locale,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a overtime entry in status idle.
    static func newOvertimeEntry(_ code: String, name: String) -> OvertimeEntry {
        return OvertimeEntry(
            code: code,
            name: name,
            procedureCode: "",
            attempts: 0,
            allergy: "",
            locale: "",
            acuity: 0,
            status: OvertimeEntryStatus.idle
        )
    }
}
