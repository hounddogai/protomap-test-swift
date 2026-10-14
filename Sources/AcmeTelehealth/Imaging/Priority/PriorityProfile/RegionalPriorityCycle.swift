import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional priority cycle is in its life cycle.
    enum RegionalPriorityCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional priority cycle as the priority team keeps it.
    final class RegionalPriorityCycle {
        var code: String
        var label: String
        var externalRef: String
        var procedureCode: String
        var revision: Int
        var expiresAt: Int
        var capacity: Int
        var name: String
        var acuity: Int
        var windowDays: Int
        var status: RegionalPriorityCycleStatus

        init(code: String, label: String, externalRef: String, procedureCode: String, revision: Int, expiresAt: Int, capacity: Int, name: String, acuity: Int, windowDays: Int, status: RegionalPriorityCycleStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.procedureCode = procedureCode
            self.revision = revision
            self.expiresAt = expiresAt
            self.capacity = capacity
            self.name = name
            self.acuity = acuity
            self.windowDays = windowDays
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

        func canMoveTo(_ next: RegionalPriorityCycleStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalPriorityCycleStatus.completed
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RegionalPriorityCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional priority cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("regional priority cycle") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(revision) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalPriorityCycle {
            return RegionalPriorityCycle(
                code: code,
                label: label,
                externalRef: externalRef,
                procedureCode: procedureCode,
                revision: revision,
                expiresAt: expiresAt,
                capacity: capacity,
                name: name,
                acuity: acuity,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional priority cycle in status planned.
    static func newRegionalPriorityCycle(_ code: String, label: String) -> RegionalPriorityCycle {
        return RegionalPriorityCycle(
            code: code,
            label: label,
            externalRef: "",
            procedureCode: "",
            revision: 0,
            expiresAt: 0,
            capacity: 0,
            name: "",
            acuity: 0,
            windowDays: 0,
            status: RegionalPriorityCycleStatus.planned
        )
    }
}
