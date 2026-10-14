import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff agreement is in its life cycle.
    enum HandoffAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a handoff agreement and its current status.
    final class HandoffAgreement {
        var code: String
        var title: String
        var bed: String
        var diagnosisCode: String
        var limit: Int
        var locale: String
        var visitMinutes: Int
        var specialty: String
        var country: String
        var dosageMg: Double
        var status: HandoffAgreementStatus

        init(code: String, title: String, bed: String, diagnosisCode: String, limit: Int, locale: String, visitMinutes: Int, specialty: String, country: String, dosageMg: Double, status: HandoffAgreementStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.diagnosisCode = diagnosisCode
            self.limit = limit
            self.locale = locale
            self.visitMinutes = visitMinutes
            self.specialty = specialty
            self.country = country
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: HandoffAgreementStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == HandoffAgreementStatus.published || next == HandoffAgreementStatus.retired
            case .published:
                return next == HandoffAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netTotal() -> Double {
            return ((dosageMg - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffAgreement {
            return HandoffAgreement(
                code: code,
                title: title,
                bed: bed,
                diagnosisCode: diagnosisCode,
                limit: limit,
                locale: locale,
                visitMinutes: visitMinutes,
                specialty: specialty,
                country: country,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a handoff agreement in status created.
    static func newHandoffAgreement(_ code: String, title: String) -> HandoffAgreement {
        return HandoffAgreement(
            code: code,
            title: title,
            bed: "",
            diagnosisCode: "",
            limit: 0,
            locale: "",
            visitMinutes: 0,
            specialty: "",
            country: "",
            dosageMg: 0.0,
            status: HandoffAgreementStatus.created
        )
    }
}
