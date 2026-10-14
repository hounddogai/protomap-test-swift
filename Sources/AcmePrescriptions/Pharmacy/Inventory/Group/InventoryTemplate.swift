import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory template is in its life cycle.
    enum InventoryTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One inventory template, with what the planners need to act on it.
    final class InventoryTemplate {
        var code: String
        var label: String
        var category: String
        var title: String
        var encounterID: String
        var priority: Int
        var durationMinutes: Int
        var diagnosisCode: String
        var status: InventoryTemplateStatus

        init(code: String, label: String, category: String, title: String, encounterID: String, priority: Int, durationMinutes: Int, diagnosisCode: String, status: InventoryTemplateStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.title = title
            self.encounterID = encounterID
            self.priority = priority
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: InventoryTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == InventoryTemplateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveValue() -> Double {
            return ((Double(priority) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryTemplate {
            return InventoryTemplate(
                code: code,
                label: label,
                category: category,
                title: title,
                encounterID: encounterID,
                priority: priority,
                durationMinutes: durationMinutes,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a inventory template in status idle.
    static func newInventoryTemplate(_ code: String, label: String) -> InventoryTemplate {
        return InventoryTemplate(
            code: code,
            label: label,
            category: "",
            title: "",
            encounterID: "",
            priority: 0,
            durationMinutes: 0,
            diagnosisCode: "",
            status: InventoryTemplateStatus.idle
        )
    }
}
