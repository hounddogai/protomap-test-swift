import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global outreach threshold is in its life cycle.
    enum GlobalOutreachThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global outreach threshold as the outreach team keeps it.
    final class GlobalOutreachThreshold {
        var code: String
        var name: String
        var windowDays: Int
        var timezone: String
        var ceiling: Double
        var priority: Int
        var endsAt: Int
        var amount: Double
        var category: String
        var updatedAt: Int
        var status: GlobalOutreachThresholdStatus

        init(code: String, name: String, windowDays: Int, timezone: String, ceiling: Double, priority: Int, endsAt: Int, amount: Double, category: String, updatedAt: Int, status: GlobalOutreachThresholdStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.timezone = timezone
            self.ceiling = ceiling
            self.priority = priority
            self.endsAt = endsAt
            self.amount = amount
            self.category = category
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: GlobalOutreachThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == GlobalOutreachThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalOutreachThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global outreach threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedVolume() -> Double {
            return ((Double(priority) - amount) * 100).rounded() / 100
        }

        func copyValue() -> GlobalOutreachThreshold {
            return GlobalOutreachThreshold(
                code: code,
                name: name,
                windowDays: windowDays,
                timezone: timezone,
                ceiling: ceiling,
                priority: priority,
                endsAt: endsAt,
                amount: amount,
                category: category,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a global outreach threshold in status planned.
    static func newGlobalOutreachThreshold(_ code: String, name: String) -> GlobalOutreachThreshold {
        return GlobalOutreachThreshold(
            code: code,
            name: name,
            windowDays: 0,
            timezone: "",
            ceiling: 0.0,
            priority: 0,
            endsAt: 0,
            amount: 0.0,
            category: "",
            updatedAt: 0,
            status: GlobalOutreachThresholdStatus.planned
        )
    }
}
