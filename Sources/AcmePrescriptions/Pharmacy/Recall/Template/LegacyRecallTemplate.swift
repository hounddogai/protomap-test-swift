import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy recall template is in its life cycle.
    enum LegacyRecallTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy recall template as the recall team keeps it.
    final class LegacyRecallTemplate {
        var code: String
        var title: String
        var minimum: Double
        var unit: String
        var clinicianID: String
        var ownerID: String
        var status: LegacyRecallTemplateStatus

        init(code: String, title: String, minimum: Double, unit: String, clinicianID: String, ownerID: String, status: LegacyRecallTemplateStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.unit = unit
            self.clinicianID = clinicianID
            self.ownerID = ownerID
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

        func canMoveTo(_ next: LegacyRecallTemplateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LegacyRecallTemplateStatus.completed
            case .inProgress:
                return next == LegacyRecallTemplateStatus.completed || next == LegacyRecallTemplateStatus.cancelled
            case .completed:
                return next == LegacyRecallTemplateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyRecallTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy recall template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> LegacyRecallTemplate {
            return LegacyRecallTemplate(
                code: code,
                title: title,
                minimum: minimum,
                unit: unit,
                clinicianID: clinicianID,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy recall template in status planned.
    static func newLegacyRecallTemplate(_ code: String, title: String) -> LegacyRecallTemplate {
        return LegacyRecallTemplate(
            code: code,
            title: title,
            minimum: 0.0,
            unit: "",
            clinicianID: "",
            ownerID: "",
            status: LegacyRecallTemplateStatus.planned
        )
    }
}
