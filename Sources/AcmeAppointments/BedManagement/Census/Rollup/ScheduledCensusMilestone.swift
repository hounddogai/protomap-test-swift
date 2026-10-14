import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled census milestone is in its life cycle.
    enum ScheduledCensusMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a scheduled census milestone and its current status.
    final class ScheduledCensusMilestone {
        var code: String
        var name: String
        var cost: Double
        var createdAt: Int
        var acuity: Int
        var title: String
        var attempts: Int
        var category: String
        var unit: String
        var batchSize: Int
        var notes: String
        var status: ScheduledCensusMilestoneStatus

        init(code: String, name: String, cost: Double, createdAt: Int, acuity: Int, title: String, attempts: Int, category: String, unit: String, batchSize: Int, notes: String, status: ScheduledCensusMilestoneStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.createdAt = createdAt
            self.acuity = acuity
            self.title = title
            self.attempts = attempts
            self.category = category
            self.unit = unit
            self.batchSize = batchSize
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledCensusMilestoneStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledCensusMilestoneStatus.validated
            case .validated:
                return next == ScheduledCensusMilestoneStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ScheduledCensusMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled census milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedValue() -> Double {
            return ((Double(batchSize) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCensusMilestone {
            return ScheduledCensusMilestone(
                code: code,
                name: name,
                cost: cost,
                createdAt: createdAt,
                acuity: acuity,
                title: title,
                attempts: attempts,
                category: category,
                unit: unit,
                batchSize: batchSize,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a scheduled census milestone in status created.
    static func newScheduledCensusMilestone(_ code: String, name: String) -> ScheduledCensusMilestone {
        return ScheduledCensusMilestone(
            code: code,
            name: name,
            cost: 0.0,
            createdAt: 0,
            acuity: 0,
            title: "",
            attempts: 0,
            category: "",
            unit: "",
            batchSize: 0,
            notes: "",
            status: ScheduledCensusMilestoneStatus.created
        )
    }
}
