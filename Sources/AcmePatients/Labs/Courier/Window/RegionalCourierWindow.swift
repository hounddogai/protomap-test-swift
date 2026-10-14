import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional courier window is in its life cycle.
    enum RegionalCourierWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A regional courier window. Its code is unique within a tenant.
    final class RegionalCourierWindow {
        var code: String
        var title: String
        var contactEmail: String
        var priority: Int
        var visible: Bool
        var diagnosisCode: String
        var status: RegionalCourierWindowStatus

        init(code: String, title: String, contactEmail: String, priority: Int, visible: Bool, diagnosisCode: String, status: RegionalCourierWindowStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.priority = priority
            self.visible = visible
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: RegionalCourierWindowStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RegionalCourierWindowStatus.draining
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

        func moveTo(_ next: RegionalCourierWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional courier window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> RegionalCourierWindow {
            return RegionalCourierWindow(
                code: code,
                title: title,
                contactEmail: contactEmail,
                priority: priority,
                visible: visible,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional courier window in status idle.
    static func newRegionalCourierWindow(_ code: String, title: String) -> RegionalCourierWindow {
        return RegionalCourierWindow(
            code: code,
            title: title,
            contactEmail: "",
            priority: 0,
            visible: false,
            diagnosisCode: "",
            status: RegionalCourierWindowStatus.idle
        )
    }
}
