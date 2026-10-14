import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority audit is in its life cycle.
    enum PriorityAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A priority audit. Its code is unique within a tenant.
    final class PriorityAudit {
        var code: String
        var label: String
        var visitMinutes: Int
        var graceDays: Int
        var ceiling: Double
        var diagnosisCode: String
        var ratio: Double
        var refills: Int
        var tags: [String]
        var facility: String
        var status: PriorityAuditStatus

        init(code: String, label: String, visitMinutes: Int, graceDays: Int, ceiling: Double, diagnosisCode: String, ratio: Double, refills: Int, tags: [String], facility: String, status: PriorityAuditStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.graceDays = graceDays
            self.ceiling = ceiling
            self.diagnosisCode = diagnosisCode
            self.ratio = ratio
            self.refills = refills
            self.tags = tags
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PriorityAuditStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PriorityAuditStatus.suspended || next == PriorityAuditStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PriorityAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("priority audit") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return (Double(refills) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> PriorityAudit {
            return PriorityAudit(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                graceDays: graceDays,
                ceiling: ceiling,
                diagnosisCode: diagnosisCode,
                ratio: ratio,
                refills: refills,
                tags: tags,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a priority audit in status draft.
    static func newPriorityAudit(_ code: String, label: String) -> PriorityAudit {
        return PriorityAudit(
            code: code,
            label: label,
            visitMinutes: 0,
            graceDays: 0,
            ceiling: 0.0,
            diagnosisCode: "",
            ratio: 0.0,
            refills: 0,
            tags: [],
            facility: "",
            status: PriorityAuditStatus.draft
        )
    }
}
