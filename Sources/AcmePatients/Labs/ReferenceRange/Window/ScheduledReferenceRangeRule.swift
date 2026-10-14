import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled reference range rule is in its life cycle.
    enum ScheduledReferenceRangeRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled reference range rule. Its code is unique within a tenant.
    final class ScheduledReferenceRangeRule {
        var code: String
        var name: String
        var specialty: String
        var checksum: String
        var amount: Double
        var floorValue: Double
        var summary: String
        var segment: String
        var bed: String
        var source: String
        var status: ScheduledReferenceRangeRuleStatus

        init(code: String, name: String, specialty: String, checksum: String, amount: Double, floorValue: Double, summary: String, segment: String, bed: String, source: String, status: ScheduledReferenceRangeRuleStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.checksum = checksum
            self.amount = amount
            self.floorValue = floorValue
            self.summary = summary
            self.segment = segment
            self.bed = bed
            self.source = source
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

        func canMoveTo(_ next: ScheduledReferenceRangeRuleStatus) -> Bool {
            switch status {
            case .draft:
                return next == ScheduledReferenceRangeRuleStatus.pending || next == ScheduledReferenceRangeRuleStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ScheduledReferenceRangeRuleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledReferenceRangeRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled reference range rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled reference range rule") \(code)"
        }

        func effectiveValue() -> Double {
            return ((amount + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledReferenceRangeRule {
            return ScheduledReferenceRangeRule(
                code: code,
                name: name,
                specialty: specialty,
                checksum: checksum,
                amount: amount,
                floorValue: floorValue,
                summary: summary,
                segment: segment,
                bed: bed,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled reference range rule in status draft.
    static func newScheduledReferenceRangeRule(_ code: String, name: String) -> ScheduledReferenceRangeRule {
        return ScheduledReferenceRangeRule(
            code: code,
            name: name,
            specialty: "",
            checksum: "",
            amount: 0.0,
            floorValue: 0.0,
            summary: "",
            segment: "",
            bed: "",
            source: "",
            status: ScheduledReferenceRangeRuleStatus.draft
        )
    }
}
