import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending panel template is in its life cycle.
    enum PendingPanelTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One pending panel template, with what the planners need to act on it.
    final class PendingPanelTemplate {
        var code: String
        var name: String
        var summary: String
        var allergy: String
        var budget: Double
        var priority: Int
        var label: String
        var encounterID: String
        var rate: Double
        var status: PendingPanelTemplateStatus

        init(code: String, name: String, summary: String, allergy: String, budget: Double, priority: Int, label: String, encounterID: String, rate: Double, status: PendingPanelTemplateStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.allergy = allergy
            self.budget = budget
            self.priority = priority
            self.label = label
            self.encounterID = encounterID
            self.rate = rate
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

        func canMoveTo(_ next: PendingPanelTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PendingPanelTemplateStatus.stopped
            case .ready:
                return next == PendingPanelTemplateStatus.stopped
            case .draining:
                return next == PendingPanelTemplateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingPanelTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending panel template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func adjustedValue() -> Double {
            return (rate * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> PendingPanelTemplate {
            return PendingPanelTemplate(
                code: code,
                name: name,
                summary: summary,
                allergy: allergy,
                budget: budget,
                priority: priority,
                label: label,
                encounterID: encounterID,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending panel template in status idle.
    static func newPendingPanelTemplate(_ code: String, name: String) -> PendingPanelTemplate {
        return PendingPanelTemplate(
            code: code,
            name: name,
            summary: "",
            allergy: "",
            budget: 0.0,
            priority: 0,
            label: "",
            encounterID: "",
            rate: 0.0,
            status: PendingPanelTemplateStatus.idle
        )
    }
}
