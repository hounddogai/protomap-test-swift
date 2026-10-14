import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task tier is in its life cycle.
    enum TaskTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a task tier and its current status.
    final class TaskTier {
        var code: String
        var name: String
        var attributes: [String: String]
        var patientRef: String
        var ownerID: String
        var maximum: Double
        var attempts: Int
        var graceDays: Int
        var amount: Double
        var source: String
        var status: TaskTierStatus

        init(code: String, name: String, attributes: [String: String], patientRef: String, ownerID: String, maximum: Double, attempts: Int, graceDays: Int, amount: Double, source: String, status: TaskTierStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.patientRef = patientRef
            self.ownerID = ownerID
            self.maximum = maximum
            self.attempts = attempts
            self.graceDays = graceDays
            self.amount = amount
            self.source = source
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

        func canMoveTo(_ next: TaskTierStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == TaskTierStatus.ready
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == TaskTierStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("task tier") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedValue() -> Double {
            return (amount * maximum * 100).rounded() / 100
        }

        func copyValue() -> TaskTier {
            return TaskTier(
                code: code,
                name: name,
                attributes: attributes,
                patientRef: patientRef,
                ownerID: ownerID,
                maximum: maximum,
                attempts: attempts,
                graceDays: graceDays,
                amount: amount,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a task tier in status idle.
    static func newTaskTier(_ code: String, name: String) -> TaskTier {
        return TaskTier(
            code: code,
            name: name,
            attributes: [:],
            patientRef: "",
            ownerID: "",
            maximum: 0.0,
            attempts: 0,
            graceDays: 0,
            amount: 0.0,
            source: "",
            status: TaskTierStatus.idle
        )
    }
}
