import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient task window is in its life cycle.
    enum LenientTaskWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a lenient task window and its current status.
    final class LenientTaskWindow {
        var code: String
        var title: String
        var windowDays: Int
        var durationMinutes: Int
        var quantity: Int
        var procedureCode: String
        var notes: String
        var status: LenientTaskWindowStatus

        init(code: String, title: String, windowDays: Int, durationMinutes: Int, quantity: Int, procedureCode: String, notes: String, status: LenientTaskWindowStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.procedureCode = procedureCode
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientTaskWindowStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientTaskWindowStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LenientTaskWindowStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientTaskWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient task window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return (Double(durationMinutes) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> LenientTaskWindow {
            return LenientTaskWindow(
                code: code,
                title: title,
                windowDays: windowDays,
                durationMinutes: durationMinutes,
                quantity: quantity,
                procedureCode: procedureCode,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient task window in status requested.
    static func newLenientTaskWindow(_ code: String, title: String) -> LenientTaskWindow {
        return LenientTaskWindow(
            code: code,
            title: title,
            windowDays: 0,
            durationMinutes: 0,
            quantity: 0,
            procedureCode: "",
            notes: "",
            status: LenientTaskWindowStatus.requested
        )
    }
}
