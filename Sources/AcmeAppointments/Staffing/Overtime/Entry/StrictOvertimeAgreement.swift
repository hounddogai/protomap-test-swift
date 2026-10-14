import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict overtime agreement is in its life cycle.
    enum StrictOvertimeAgreementStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A strict overtime agreement. Its code is unique within a tenant.
    final class StrictOvertimeAgreement {
        var code: String
        var title: String
        var pinned: Bool
        var summary: String
        var threshold: Double
        var allergy: String
        var dosageMg: Double
        var encounterID: String
        var acuity: Int
        var retries: Int
        var source: String
        var status: StrictOvertimeAgreementStatus

        init(code: String, title: String, pinned: Bool, summary: String, threshold: Double, allergy: String, dosageMg: Double, encounterID: String, acuity: Int, retries: Int, source: String, status: StrictOvertimeAgreementStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.summary = summary
            self.threshold = threshold
            self.allergy = allergy
            self.dosageMg = dosageMg
            self.encounterID = encounterID
            self.acuity = acuity
            self.retries = retries
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictOvertimeAgreementStatus) -> Bool {
            switch status {
            case .requested:
                return next == StrictOvertimeAgreementStatus.granted
            case .granted:
                return next == StrictOvertimeAgreementStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: StrictOvertimeAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict overtime agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedValue() -> Double {
            return ((threshold + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> StrictOvertimeAgreement {
            return StrictOvertimeAgreement(
                code: code,
                title: title,
                pinned: pinned,
                summary: summary,
                threshold: threshold,
                allergy: allergy,
                dosageMg: dosageMg,
                encounterID: encounterID,
                acuity: acuity,
                retries: retries,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a strict overtime agreement in status requested.
    static func newStrictOvertimeAgreement(_ code: String, title: String) -> StrictOvertimeAgreement {
        return StrictOvertimeAgreement(
            code: code,
            title: title,
            pinned: false,
            summary: "",
            threshold: 0.0,
            allergy: "",
            dosageMg: 0.0,
            encounterID: "",
            acuity: 0,
            retries: 0,
            source: "",
            status: StrictOvertimeAgreementStatus.requested
        )
    }
}
