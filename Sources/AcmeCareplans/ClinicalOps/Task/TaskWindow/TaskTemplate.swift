import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task template is in its life cycle.
    enum TaskTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a task template and its current status.
    final class TaskTemplate {
        var code: String
        var name: String
        var ratio: Double
        var version: Int
        var quantity: Int
        var checksum: String
        var attempts: Int
        var attributes: [String: String]
        var label: String
        var graceDays: Int
        var status: TaskTemplateStatus

        init(code: String, name: String, ratio: Double, version: Int, quantity: Int, checksum: String, attempts: Int, attributes: [String: String], label: String, graceDays: Int, status: TaskTemplateStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.version = version
            self.quantity = quantity
            self.checksum = checksum
            self.attempts = attempts
            self.attributes = attributes
            self.label = label
            self.graceDays = graceDays
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

        func canMoveTo(_ next: TaskTemplateStatus) -> Bool {
            switch status {
            case .idle:
                return next == TaskTemplateStatus.warming || next == TaskTemplateStatus.draining
            case .warming:
                return next == TaskTemplateStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TaskTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
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

        func weightedVolume() -> Double {
            return ((Double(graceDays) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> TaskTemplate {
            return TaskTemplate(
                code: code,
                name: name,
                ratio: ratio,
                version: version,
                quantity: quantity,
                checksum: checksum,
                attempts: attempts,
                attributes: attributes,
                label: label,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a task template in status idle.
    static func newTaskTemplate(_ code: String, name: String) -> TaskTemplate {
        return TaskTemplate(
            code: code,
            name: name,
            ratio: 0.0,
            version: 0,
            quantity: 0,
            checksum: "",
            attempts: 0,
            attributes: [:],
            label: "",
            graceDays: 0,
            status: TaskTemplateStatus.idle
        )
    }
}
