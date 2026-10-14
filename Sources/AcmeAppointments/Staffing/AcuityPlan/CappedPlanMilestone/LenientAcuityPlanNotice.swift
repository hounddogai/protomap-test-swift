import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient acuity plan notice is in its life cycle.
    enum LenientAcuityPlanNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a lenient acuity plan notice and its current status.
    final class LenientAcuityPlanNotice {
        var code: String
        var title: String
        var specialty: String
        var discount: Double
        var encounterID: String
        var limit: Int
        var dosageMg: Double
        var attributes: [String: String]
        var status: LenientAcuityPlanNoticeStatus

        init(code: String, title: String, specialty: String, discount: Double, encounterID: String, limit: Int, dosageMg: Double, attributes: [String: String], status: LenientAcuityPlanNoticeStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.discount = discount
            self.encounterID = encounterID
            self.limit = limit
            self.dosageMg = dosageMg
            self.attributes = attributes
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

        func canMoveTo(_ next: LenientAcuityPlanNoticeStatus) -> Bool {
            switch status {
            case .created:
                return next == LenientAcuityPlanNoticeStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LenientAcuityPlanNoticeStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientAcuityPlanNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient acuity plan notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedTotal() -> Double {
            return (dosageMg * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> LenientAcuityPlanNotice {
            return LenientAcuityPlanNotice(
                code: code,
                title: title,
                specialty: specialty,
                discount: discount,
                encounterID: encounterID,
                limit: limit,
                dosageMg: dosageMg,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient acuity plan notice in status created.
    static func newLenientAcuityPlanNotice(_ code: String, title: String) -> LenientAcuityPlanNotice {
        return LenientAcuityPlanNotice(
            code: code,
            title: title,
            specialty: "",
            discount: 0.0,
            encounterID: "",
            limit: 0,
            dosageMg: 0.0,
            attributes: [:],
            status: LenientAcuityPlanNoticeStatus.created
        )
    }
}
