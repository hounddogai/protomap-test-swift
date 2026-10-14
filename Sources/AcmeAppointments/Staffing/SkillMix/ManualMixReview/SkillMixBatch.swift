import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix batch is in its life cycle.
    enum SkillMixBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One skill mix batch, with what the planners need to act on it.
    final class SkillMixBatch {
        var code: String
        var title: String
        var bed: String
        var summary: String
        var minimum: Double
        var unit: String
        var label: String
        var visible: Bool
        var status: SkillMixBatchStatus

        init(code: String, title: String, bed: String, summary: String, minimum: Double, unit: String, label: String, visible: Bool, status: SkillMixBatchStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.summary = summary
            self.minimum = minimum
            self.unit = unit
            self.label = label
            self.visible = visible
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

        func canMoveTo(_ next: SkillMixBatchStatus) -> Bool {
            switch status {
            case .created:
                return next == SkillMixBatchStatus.validated || next == SkillMixBatchStatus.retired
            case .validated:
                return next == SkillMixBatchStatus.published || next == SkillMixBatchStatus.retired
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

        func moveTo(_ next: SkillMixBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> SkillMixBatch {
            return SkillMixBatch(
                code: code,
                title: title,
                bed: bed,
                summary: summary,
                minimum: minimum,
                unit: unit,
                label: label,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a skill mix batch in status created.
    static func newSkillMixBatch(_ code: String, title: String) -> SkillMixBatch {
        return SkillMixBatch(
            code: code,
            title: title,
            bed: "",
            summary: "",
            minimum: 0.0,
            unit: "",
            label: "",
            visible: false,
            status: SkillMixBatchStatus.created
        )
    }
}
