import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding template is in its life cycle.
    enum RoundingTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rounding template. Its code is unique within a tenant.
    final class RoundingTemplate {
        var code: String
        var name: String
        var patientRef: String
        var acuity: Int
        var minimum: Double
        var locale: String
        var channel: String
        var margin: Double
        var status: RoundingTemplateStatus

        init(code: String, name: String, patientRef: String, acuity: Int, minimum: Double, locale: String, channel: String, margin: Double, status: RoundingTemplateStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.acuity = acuity
            self.minimum = minimum
            self.locale = locale
            self.channel = channel
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RoundingTemplateStatus) -> Bool {
            switch status {
            case .draft:
                return next == RoundingTemplateStatus.pending || next == RoundingTemplateStatus.closed
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RoundingTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedValue() -> Double {
            return ((minimum + margin) * 100).rounded() / 100
        }

        func copyValue() -> RoundingTemplate {
            return RoundingTemplate(
                code: code,
                name: name,
                patientRef: patientRef,
                acuity: acuity,
                minimum: minimum,
                locale: locale,
                channel: channel,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rounding template in status draft.
    static func newRoundingTemplate(_ code: String, name: String) -> RoundingTemplate {
        return RoundingTemplate(
            code: code,
            name: name,
            patientRef: "",
            acuity: 0,
            minimum: 0.0,
            locale: "",
            channel: "",
            margin: 0.0,
            status: RoundingTemplateStatus.draft
        )
    }
}
