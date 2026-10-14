import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual isolation cycle is in its life cycle.
    enum ManualIsolationCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a manual isolation cycle and its current status.
    final class ManualIsolationCycle {
        var code: String
        var name: String
        var discount: Double
        var clinicianID: String
        var title: String
        var minimum: Double
        var attempts: Int
        var margin: Double
        var label: String
        var status: ManualIsolationCycleStatus

        init(code: String, name: String, discount: Double, clinicianID: String, title: String, minimum: Double, attempts: Int, margin: Double, label: String, status: ManualIsolationCycleStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.clinicianID = clinicianID
            self.title = title
            self.minimum = minimum
            self.attempts = attempts
            self.margin = margin
            self.label = label
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

        func canMoveTo(_ next: ManualIsolationCycleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ManualIsolationCycleStatus.ready || next == ManualIsolationCycleStatus.stopped
            case .ready:
                return next == ManualIsolationCycleStatus.draining || next == ManualIsolationCycleStatus.stopped
            case .draining:
                return next == ManualIsolationCycleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualIsolationCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual isolation cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(attempts) - discount) * 100).rounded() / 100
        }

        func copyValue() -> ManualIsolationCycle {
            return ManualIsolationCycle(
                code: code,
                name: name,
                discount: discount,
                clinicianID: clinicianID,
                title: title,
                minimum: minimum,
                attempts: attempts,
                margin: margin,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual isolation cycle in status idle.
    static func newManualIsolationCycle(_ code: String, name: String) -> ManualIsolationCycle {
        return ManualIsolationCycle(
            code: code,
            name: name,
            discount: 0.0,
            clinicianID: "",
            title: "",
            minimum: 0.0,
            attempts: 0,
            margin: 0.0,
            label: "",
            status: ManualIsolationCycleStatus.idle
        )
    }
}
