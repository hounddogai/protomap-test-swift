import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan draft is in its life cycle.
    enum AcuityPlanDraftStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A acuity plan draft as the acuity plan team keeps it.
    final class AcuityPlanDraft {
        var code: String
        var label: String
        var allergy: String
        var summary: String
        var bed: String
        var tags: [String]
        var name: String
        var acuity: Int
        var status: AcuityPlanDraftStatus

        init(code: String, label: String, allergy: String, summary: String, bed: String, tags: [String], name: String, acuity: Int, status: AcuityPlanDraftStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.summary = summary
            self.bed = bed
            self.tags = tags
            self.name = name
            self.acuity = acuity
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

        func canMoveTo(_ next: AcuityPlanDraftStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AcuityPlanDraftStatus.draining || next == AcuityPlanDraftStatus.stopped
            case .ready:
                return next == AcuityPlanDraftStatus.draining
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

        func moveTo(_ next: AcuityPlanDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> AcuityPlanDraft {
            return AcuityPlanDraft(
                code: code,
                label: label,
                allergy: allergy,
                summary: summary,
                bed: bed,
                tags: tags,
                name: name,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a acuity plan draft in status idle.
    static func newAcuityPlanDraft(_ code: String, label: String) -> AcuityPlanDraft {
        return AcuityPlanDraft(
            code: code,
            label: label,
            allergy: "",
            summary: "",
            bed: "",
            tags: [],
            name: "",
            acuity: 0,
            status: AcuityPlanDraftStatus.idle
        )
    }
}
