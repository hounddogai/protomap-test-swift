import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan target is in its life cycle.
    enum AcuityPlanTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a acuity plan target and its current status.
    final class AcuityPlanTarget {
        var code: String
        var title: String
        var tags: [String]
        var source: String
        var bed: String
        var summary: String
        var category: String
        var patientRef: String
        var active: Bool
        var graceDays: Int
        var currency: String
        var status: AcuityPlanTargetStatus

        init(code: String, title: String, tags: [String], source: String, bed: String, summary: String, category: String, patientRef: String, active: Bool, graceDays: Int, currency: String, status: AcuityPlanTargetStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.source = source
            self.bed = bed
            self.summary = summary
            self.category = category
            self.patientRef = patientRef
            self.active = active
            self.graceDays = graceDays
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AcuityPlanTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AcuityPlanTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
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
            return Double(graceDays)
        }

        func copyValue() -> AcuityPlanTarget {
            return AcuityPlanTarget(
                code: code,
                title: title,
                tags: tags,
                source: source,
                bed: bed,
                summary: summary,
                category: category,
                patientRef: patientRef,
                active: active,
                graceDays: graceDays,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a acuity plan target in status proposed.
    static func newAcuityPlanTarget(_ code: String, title: String) -> AcuityPlanTarget {
        return AcuityPlanTarget(
            code: code,
            title: title,
            tags: [],
            source: "",
            bed: "",
            summary: "",
            category: "",
            patientRef: "",
            active: false,
            graceDays: 0,
            currency: "",
            status: AcuityPlanTargetStatus.proposed
        )
    }
}
