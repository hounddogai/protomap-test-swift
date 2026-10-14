import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form template is in its life cycle.
    enum ConsentFormTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a consent form template and its current status.
    final class ConsentFormTemplate {
        var code: String
        var title: String
        var patientRef: String
        var checksum: String
        var visible: Bool
        var quantity: Int
        var status: ConsentFormTemplateStatus

        init(code: String, title: String, patientRef: String, checksum: String, visible: Bool, quantity: Int, status: ConsentFormTemplateStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.checksum = checksum
            self.visible = visible
            self.quantity = quantity
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

        func canMoveTo(_ next: ConsentFormTemplateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ConsentFormTemplateStatus.suspended || next == ConsentFormTemplateStatus.closed
            case .suspended:
                return next == ConsentFormTemplateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("consent form template") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ConsentFormTemplate {
            return ConsentFormTemplate(
                code: code,
                title: title,
                patientRef: patientRef,
                checksum: checksum,
                visible: visible,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a consent form template in status draft.
    static func newConsentFormTemplate(_ code: String, title: String) -> ConsentFormTemplate {
        return ConsentFormTemplate(
            code: code,
            title: title,
            patientRef: "",
            checksum: "",
            visible: false,
            quantity: 0,
            status: ConsentFormTemplateStatus.draft
        )
    }
}
