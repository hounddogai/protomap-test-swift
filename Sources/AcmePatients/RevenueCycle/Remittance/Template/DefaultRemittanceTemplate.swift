import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default remittance template is in its life cycle.
    enum DefaultRemittanceTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One default remittance template, with what the planners need to act on it.
    final class DefaultRemittanceTemplate {
        var code: String
        var label: String
        var createdAt: Int
        var graceDays: Int
        var timezone: String
        var reviewer: String
        var updatedAt: Int
        var priority: Int
        var ceiling: Double
        var endsAt: Int
        var notes: String
        var status: DefaultRemittanceTemplateStatus

        init(code: String, label: String, createdAt: Int, graceDays: Int, timezone: String, reviewer: String, updatedAt: Int, priority: Int, ceiling: Double, endsAt: Int, notes: String, status: DefaultRemittanceTemplateStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.graceDays = graceDays
            self.timezone = timezone
            self.reviewer = reviewer
            self.updatedAt = updatedAt
            self.priority = priority
            self.ceiling = ceiling
            self.endsAt = endsAt
            self.notes = notes
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

        func canMoveTo(_ next: DefaultRemittanceTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DefaultRemittanceTemplateStatus.ready || next == DefaultRemittanceTemplateStatus.stopped
            case .ready:
                return next == DefaultRemittanceTemplateStatus.draining
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

        func moveTo(_ next: DefaultRemittanceTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default remittance template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedVolume() -> Double {
            return (Double(endsAt) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> DefaultRemittanceTemplate {
            return DefaultRemittanceTemplate(
                code: code,
                label: label,
                createdAt: createdAt,
                graceDays: graceDays,
                timezone: timezone,
                reviewer: reviewer,
                updatedAt: updatedAt,
                priority: priority,
                ceiling: ceiling,
                endsAt: endsAt,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default remittance template in status idle.
    static func newDefaultRemittanceTemplate(_ code: String, label: String) -> DefaultRemittanceTemplate {
        return DefaultRemittanceTemplate(
            code: code,
            label: label,
            createdAt: 0,
            graceDays: 0,
            timezone: "",
            reviewer: "",
            updatedAt: 0,
            priority: 0,
            ceiling: 0.0,
            endsAt: 0,
            notes: "",
            status: DefaultRemittanceTemplateStatus.idle
        )
    }
}
