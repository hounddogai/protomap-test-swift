import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift exception is in its life cycle.
    enum ShiftExceptionStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A shift exception. Its code is unique within a tenant.
    final class ShiftException {
        var code: String
        var title: String
        var summary: String
        var dosageMg: Double
        var source: String
        var minimum: Double
        var notes: String
        var phone: String
        var name: String
        var copay: Double
        var status: ShiftExceptionStatus

        init(code: String, title: String, summary: String, dosageMg: Double, source: String, minimum: Double, notes: String, phone: String, name: String, copay: Double, status: ShiftExceptionStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.dosageMg = dosageMg
            self.source = source
            self.minimum = minimum
            self.notes = notes
            self.phone = phone
            self.name = name
            self.copay = copay
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

        func canMoveTo(_ next: ShiftExceptionStatus) -> Bool {
            switch status {
            case .draft:
                return next == ShiftExceptionStatus.suspended || next == ShiftExceptionStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: ShiftExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return ((minimum + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ShiftException {
            return ShiftException(
                code: code,
                title: title,
                summary: summary,
                dosageMg: dosageMg,
                source: source,
                minimum: minimum,
                notes: notes,
                phone: phone,
                name: name,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a shift exception in status draft.
    static func newShiftException(_ code: String, title: String) -> ShiftException {
        return ShiftException(
            code: code,
            title: title,
            summary: "",
            dosageMg: 0.0,
            source: "",
            minimum: 0.0,
            notes: "",
            phone: "",
            name: "",
            copay: 0.0,
            status: ShiftExceptionStatus.draft
        )
    }
}
