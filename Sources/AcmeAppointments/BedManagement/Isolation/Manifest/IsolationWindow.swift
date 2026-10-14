import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation window is in its life cycle.
    enum IsolationWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A isolation window. Its code is unique within a tenant.
    final class IsolationWindow {
        var code: String
        var label: String
        var budget: Double
        var currency: String
        var patientRef: String
        var refills: Int
        var expiresAt: Int
        var bed: String
        var specialty: String
        var status: IsolationWindowStatus

        init(code: String, label: String, budget: Double, currency: String, patientRef: String, refills: Int, expiresAt: Int, bed: String, specialty: String, status: IsolationWindowStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.currency = currency
            self.patientRef = patientRef
            self.refills = refills
            self.expiresAt = expiresAt
            self.bed = bed
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationWindowStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == IsolationWindowStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: IsolationWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("isolation window") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(refills) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> IsolationWindow {
            return IsolationWindow(
                code: code,
                label: label,
                budget: budget,
                currency: currency,
                patientRef: patientRef,
                refills: refills,
                expiresAt: expiresAt,
                bed: bed,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a isolation window in status planned.
    static func newIsolationWindow(_ code: String, label: String) -> IsolationWindow {
        return IsolationWindow(
            code: code,
            label: label,
            budget: 0.0,
            currency: "",
            patientRef: "",
            refills: 0,
            expiresAt: 0,
            bed: "",
            specialty: "",
            status: IsolationWindowStatus.planned
        )
    }
}
