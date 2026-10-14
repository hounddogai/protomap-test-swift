import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback order set window is in its life cycle.
    enum FallbackOrderSetWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback order set window. Its code is unique within a tenant.
    final class FallbackOrderSetWindow {
        var code: String
        var label: String
        var payer: String
        var encounterID: String
        var attempts: Int
        var visitMinutes: Int
        var status: FallbackOrderSetWindowStatus

        init(code: String, label: String, payer: String, encounterID: String, attempts: Int, visitMinutes: Int, status: FallbackOrderSetWindowStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.encounterID = encounterID
            self.attempts = attempts
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: FallbackOrderSetWindowStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackOrderSetWindowStatus.warming || next == FallbackOrderSetWindowStatus.stopped
            case .warming:
                return next == FallbackOrderSetWindowStatus.stopped
            case .ready:
                return next == FallbackOrderSetWindowStatus.draining
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

        func moveTo(_ next: FallbackOrderSetWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback order set window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback order set window") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(visitMinutes) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackOrderSetWindow {
            return FallbackOrderSetWindow(
                code: code,
                label: label,
                payer: payer,
                encounterID: encounterID,
                attempts: attempts,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback order set window in status idle.
    static func newFallbackOrderSetWindow(_ code: String, label: String) -> FallbackOrderSetWindow {
        return FallbackOrderSetWindow(
            code: code,
            label: label,
            payer: "",
            encounterID: "",
            attempts: 0,
            visitMinutes: 0,
            status: FallbackOrderSetWindowStatus.idle
        )
    }
}
