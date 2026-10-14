import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient language agreement is in its life cycle.
    enum LenientLanguageAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a lenient language agreement and its current status.
    final class LenientLanguageAgreement {
        var code: String
        var title: String
        var bed: String
        var diagnosisCode: String
        var createdAt: Int
        var status: LenientLanguageAgreementStatus

        init(code: String, title: String, bed: String, diagnosisCode: String, createdAt: Int, status: LenientLanguageAgreementStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.diagnosisCode = diagnosisCode
            self.createdAt = createdAt
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

        func canMoveTo(_ next: LenientLanguageAgreementStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LenientLanguageAgreementStatus.closed
            case .suspended:
                return next == LenientLanguageAgreementStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientLanguageAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient language agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> LenientLanguageAgreement {
            return LenientLanguageAgreement(
                code: code,
                title: title,
                bed: bed,
                diagnosisCode: diagnosisCode,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient language agreement in status draft.
    static func newLenientLanguageAgreement(_ code: String, title: String) -> LenientLanguageAgreement {
        return LenientLanguageAgreement(
            code: code,
            title: title,
            bed: "",
            diagnosisCode: "",
            createdAt: 0,
            status: LenientLanguageAgreementStatus.draft
        )
    }
}
