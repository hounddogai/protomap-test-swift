import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient program window is in its life cycle.
    enum LenientProgramWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient program window as the program team keeps it.
    final class LenientProgramWindow {
        var code: String
        var name: String
        var threshold: Double
        var endsAt: Int
        var allergy: String
        var status: LenientProgramWindowStatus

        init(code: String, name: String, threshold: Double, endsAt: Int, allergy: String, status: LenientProgramWindowStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.endsAt = endsAt
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientProgramWindowStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientProgramWindowStatus.rejected || next == LenientProgramWindowStatus.withdrawn
            case .approved:
                return next == LenientProgramWindowStatus.rejected || next == LenientProgramWindowStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LenientProgramWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient program window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient program window") \(code)"
        }

        func adjustedValue() -> Double {
            return ((threshold - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientProgramWindow {
            return LenientProgramWindow(
                code: code,
                name: name,
                threshold: threshold,
                endsAt: endsAt,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient program window in status proposed.
    static func newLenientProgramWindow(_ code: String, name: String) -> LenientProgramWindow {
        return LenientProgramWindow(
            code: code,
            name: name,
            threshold: 0.0,
            endsAt: 0,
            allergy: "",
            status: LenientProgramWindowStatus.proposed
        )
    }
}
