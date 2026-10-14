import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot window is in its life cycle.
    enum SlotWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A slot window. Its code is unique within a tenant.
    final class SlotWindow {
        var code: String
        var label: String
        var threshold: Double
        var externalRef: String
        var title: String
        var specialty: String
        var visitMinutes: Int
        var durationMinutes: Int
        var procedureCode: String
        var status: SlotWindowStatus

        init(code: String, label: String, threshold: Double, externalRef: String, title: String, specialty: String, visitMinutes: Int, durationMinutes: Int, procedureCode: String, status: SlotWindowStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.externalRef = externalRef
            self.title = title
            self.specialty = specialty
            self.visitMinutes = visitMinutes
            self.durationMinutes = durationMinutes
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: SlotWindowStatus) -> Bool {
            switch status {
            case .draft:
                return next == SlotWindowStatus.closed
            case .pending:
                return next == SlotWindowStatus.suspended || next == SlotWindowStatus.closed
            case .active:
                return next == SlotWindowStatus.suspended || next == SlotWindowStatus.closed
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

        func moveTo(_ next: SlotWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("slot window") \(code)"
        }

        func effectiveLoad() -> Double {
            return (Double(durationMinutes) * threshold * 100).rounded() / 100
        }

        func copyValue() -> SlotWindow {
            return SlotWindow(
                code: code,
                label: label,
                threshold: threshold,
                externalRef: externalRef,
                title: title,
                specialty: specialty,
                visitMinutes: visitMinutes,
                durationMinutes: durationMinutes,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a slot window in status draft.
    static func newSlotWindow(_ code: String, label: String) -> SlotWindow {
        return SlotWindow(
            code: code,
            label: label,
            threshold: 0.0,
            externalRef: "",
            title: "",
            specialty: "",
            visitMinutes: 0,
            durationMinutes: 0,
            procedureCode: "",
            status: SlotWindowStatus.draft
        )
    }
}
