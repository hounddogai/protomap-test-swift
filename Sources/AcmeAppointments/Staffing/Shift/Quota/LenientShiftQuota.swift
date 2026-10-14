import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient shift quota is in its life cycle.
    enum LenientShiftQuotaStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient shift quota as the shift team keeps it.
    final class LenientShiftQuota {
        var code: String
        var label: String
        var endsAt: Int
        var startsAt: Int
        var facility: String
        var tags: [String]
        var patientRef: String
        var score: Double
        var source: String
        var procedureCode: String
        var graceDays: Int
        var status: LenientShiftQuotaStatus

        init(code: String, label: String, endsAt: Int, startsAt: Int, facility: String, tags: [String], patientRef: String, score: Double, source: String, procedureCode: String, graceDays: Int, status: LenientShiftQuotaStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.facility = facility
            self.tags = tags
            self.patientRef = patientRef
            self.score = score
            self.source = source
            self.procedureCode = procedureCode
            self.graceDays = graceDays
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

        func canMoveTo(_ next: LenientShiftQuotaStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientShiftQuotaStatus.suspended || next == LenientShiftQuotaStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LenientShiftQuotaStatus.suspended || next == LenientShiftQuotaStatus.closed
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

        func moveTo(_ next: LenientShiftQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient shift quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("lenient shift quota") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return (Double(endsAt) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> LenientShiftQuota {
            return LenientShiftQuota(
                code: code,
                label: label,
                endsAt: endsAt,
                startsAt: startsAt,
                facility: facility,
                tags: tags,
                patientRef: patientRef,
                score: score,
                source: source,
                procedureCode: procedureCode,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a lenient shift quota in status draft.
    static func newLenientShiftQuota(_ code: String, label: String) -> LenientShiftQuota {
        return LenientShiftQuota(
            code: code,
            label: label,
            endsAt: 0,
            startsAt: 0,
            facility: "",
            tags: [],
            patientRef: "",
            score: 0.0,
            source: "",
            procedureCode: "",
            graceDays: 0,
            status: LenientShiftQuotaStatus.draft
        )
    }
}
