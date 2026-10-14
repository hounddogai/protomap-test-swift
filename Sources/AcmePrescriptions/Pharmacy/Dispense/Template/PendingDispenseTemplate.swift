import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending dispense template is in its life cycle.
    enum PendingDispenseTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending dispense template as the dispense team keeps it.
    final class PendingDispenseTemplate {
        var code: String
        var title: String
        var dosageMg: Double
        var windowDays: Int
        var description: String
        var budget: Double
        var bed: String
        var status: PendingDispenseTemplateStatus

        init(code: String, title: String, dosageMg: Double, windowDays: Int, description: String, budget: Double, bed: String, status: PendingDispenseTemplateStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.windowDays = windowDays
            self.description = description
            self.budget = budget
            self.bed = bed
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

        func canMoveTo(_ next: PendingDispenseTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PendingDispenseTemplateStatus.draining || next == PendingDispenseTemplateStatus.stopped
            case .draining:
                return next == PendingDispenseTemplateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingDispenseTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending dispense template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return ((budget - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> PendingDispenseTemplate {
            return PendingDispenseTemplate(
                code: code,
                title: title,
                dosageMg: dosageMg,
                windowDays: windowDays,
                description: description,
                budget: budget,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending dispense template in status idle.
    static func newPendingDispenseTemplate(_ code: String, title: String) -> PendingDispenseTemplate {
        return PendingDispenseTemplate(
            code: code,
            title: title,
            dosageMg: 0.0,
            windowDays: 0,
            description: "",
            budget: 0.0,
            bed: "",
            status: PendingDispenseTemplateStatus.idle
        )
    }
}
