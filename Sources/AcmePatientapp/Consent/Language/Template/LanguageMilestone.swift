import AcmePlatform
import Foundation

extension Consent {
    /// Where a language milestone is in its life cycle.
    enum LanguageMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A language milestone as the language team keeps it.
    final class LanguageMilestone {
        var code: String
        var name: String
        var windowDays: Int
        var version: Int
        var description: String
        var visitMinutes: Int
        var locale: String
        var patientRef: String
        var status: LanguageMilestoneStatus

        init(code: String, name: String, windowDays: Int, version: Int, description: String, visitMinutes: Int, locale: String, patientRef: String, status: LanguageMilestoneStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.version = version
            self.description = description
            self.visitMinutes = visitMinutes
            self.locale = locale
            self.patientRef = patientRef
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

        func canMoveTo(_ next: LanguageMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LanguageMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return ((Double(version) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageMilestone {
            return LanguageMilestone(
                code: code,
                name: name,
                windowDays: windowDays,
                version: version,
                description: description,
                visitMinutes: visitMinutes,
                locale: locale,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a language milestone in status idle.
    static func newLanguageMilestone(_ code: String, name: String) -> LanguageMilestone {
        return LanguageMilestone(
            code: code,
            name: name,
            windowDays: 0,
            version: 0,
            description: "",
            visitMinutes: 0,
            locale: "",
            patientRef: "",
            status: LanguageMilestoneStatus.idle
        )
    }
}
