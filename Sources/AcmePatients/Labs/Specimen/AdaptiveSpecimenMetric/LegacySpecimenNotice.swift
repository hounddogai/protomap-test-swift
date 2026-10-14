import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy specimen notice is in its life cycle.
    enum LegacySpecimenNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy specimen notice. Its code is unique within a tenant.
    final class LegacySpecimenNotice {
        var code: String
        var title: String
        var attempts: Int
        var summary: String
        var diagnosisCode: String
        var category: String
        var sequence: Int
        var unit: String
        var currency: String
        var status: LegacySpecimenNoticeStatus

        init(code: String, title: String, attempts: Int, summary: String, diagnosisCode: String, category: String, sequence: Int, unit: String, currency: String, status: LegacySpecimenNoticeStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.category = category
            self.sequence = sequence
            self.unit = unit
            self.currency = currency
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

        func canMoveTo(_ next: LegacySpecimenNoticeStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacySpecimenNoticeStatus.reopened || next == LegacySpecimenNoticeStatus.archived
            case .inReview:
                return next == LegacySpecimenNoticeStatus.reopened
            case .resolved:
                return next == LegacySpecimenNoticeStatus.reopened
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

        func moveTo(_ next: LegacySpecimenNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy specimen notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return ((Double(attempts) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> LegacySpecimenNotice {
            return LegacySpecimenNotice(
                code: code,
                title: title,
                attempts: attempts,
                summary: summary,
                diagnosisCode: diagnosisCode,
                category: category,
                sequence: sequence,
                unit: unit,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a legacy specimen notice in status open.
    static func newLegacySpecimenNotice(_ code: String, title: String) -> LegacySpecimenNotice {
        return LegacySpecimenNotice(
            code: code,
            title: title,
            attempts: 0,
            summary: "",
            diagnosisCode: "",
            category: "",
            sequence: 0,
            unit: "",
            currency: "",
            status: LegacySpecimenNoticeStatus.`open`
        )
    }
}
