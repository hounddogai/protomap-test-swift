import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional reference range audit is in its life cycle.
    enum RegionalReferenceRangeAuditStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One regional reference range audit, with what the planners need to act on it.
    final class RegionalReferenceRangeAudit {
        var code: String
        var label: String
        var locale: String
        var clinicianID: String
        var segment: String
        var rate: Double
        var active: Bool
        var specialty: String
        var status: RegionalReferenceRangeAuditStatus

        init(code: String, label: String, locale: String, clinicianID: String, segment: String, rate: Double, active: Bool, specialty: String, status: RegionalReferenceRangeAuditStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.clinicianID = clinicianID
            self.segment = segment
            self.rate = rate
            self.active = active
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalReferenceRangeAuditStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalReferenceRangeAuditStatus.inReview
            case .inReview:
                return next == RegionalReferenceRangeAuditStatus.resolved || next == RegionalReferenceRangeAuditStatus.archived
            case .resolved:
                return next == RegionalReferenceRangeAuditStatus.reopened || next == RegionalReferenceRangeAuditStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RegionalReferenceRangeAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional reference range audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> RegionalReferenceRangeAudit {
            return RegionalReferenceRangeAudit(
                code: code,
                label: label,
                locale: locale,
                clinicianID: clinicianID,
                segment: segment,
                rate: rate,
                active: active,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional reference range audit in status open.
    static func newRegionalReferenceRangeAudit(_ code: String, label: String) -> RegionalReferenceRangeAudit {
        return RegionalReferenceRangeAudit(
            code: code,
            label: label,
            locale: "",
            clinicianID: "",
            segment: "",
            rate: 0.0,
            active: false,
            specialty: "",
            status: RegionalReferenceRangeAuditStatus.`open`
        )
    }
}
