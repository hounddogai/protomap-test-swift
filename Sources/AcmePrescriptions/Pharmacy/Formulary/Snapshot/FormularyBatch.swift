import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary batch is in its life cycle.
    enum FormularyBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a formulary batch and its current status.
    final class FormularyBatch {
        var code: String
        var title: String
        var locale: String
        var dosageMg: Double
        var visible: Bool
        var status: FormularyBatchStatus

        init(code: String, title: String, locale: String, dosageMg: Double, visible: Bool, status: FormularyBatchStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.dosageMg = dosageMg
            self.visible = visible
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

        func canMoveTo(_ next: FormularyBatchStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == FormularyBatchStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: FormularyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> FormularyBatch {
            return FormularyBatch(
                code: code,
                title: title,
                locale: locale,
                dosageMg: dosageMg,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a formulary batch in status open.
    static func newFormularyBatch(_ code: String, title: String) -> FormularyBatch {
        return FormularyBatch(
            code: code,
            title: title,
            locale: "",
            dosageMg: 0.0,
            visible: false,
            status: FormularyBatchStatus.`open`
        )
    }
}
