import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient isolation template is in its life cycle.
    enum LenientIsolationTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One lenient isolation template, with what the planners need to act on it.
    final class LenientIsolationTemplate {
        var code: String
        var title: String
        var specialty: String
        var patientRef: String
        var priority: Int
        var expiresAt: Int
        var locale: String
        var status: LenientIsolationTemplateStatus

        init(code: String, title: String, specialty: String, patientRef: String, priority: Int, expiresAt: Int, locale: String, status: LenientIsolationTemplateStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.patientRef = patientRef
            self.priority = priority
            self.expiresAt = expiresAt
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientIsolationTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == LenientIsolationTemplateStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LenientIsolationTemplateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientIsolationTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient isolation template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedLoad() -> Double {
            return ((Double(priority) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientIsolationTemplate {
            return LenientIsolationTemplate(
                code: code,
                title: title,
                specialty: specialty,
                patientRef: patientRef,
                priority: priority,
                expiresAt: expiresAt,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient isolation template in status open.
    static func newLenientIsolationTemplate(_ code: String, title: String) -> LenientIsolationTemplate {
        return LenientIsolationTemplate(
            code: code,
            title: title,
            specialty: "",
            patientRef: "",
            priority: 0,
            expiresAt: 0,
            locale: "",
            status: LenientIsolationTemplateStatus.`open`
        )
    }
}
