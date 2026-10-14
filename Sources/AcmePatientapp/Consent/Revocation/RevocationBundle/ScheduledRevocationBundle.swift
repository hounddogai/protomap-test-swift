import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled revocation bundle is in its life cycle.
    enum ScheduledRevocationBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A scheduled revocation bundle as the revocation team keeps it.
    final class ScheduledRevocationBundle {
        var code: String
        var title: String
        var sequence: Int
        var phone: String
        var description: String
        var region: String
        var graceDays: Int
        var dosageMg: Double
        var diagnosisCode: String
        var status: ScheduledRevocationBundleStatus

        init(code: String, title: String, sequence: Int, phone: String, description: String, region: String, graceDays: Int, dosageMg: Double, diagnosisCode: String, status: ScheduledRevocationBundleStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.phone = phone
            self.description = description
            self.region = region
            self.graceDays = graceDays
            self.dosageMg = dosageMg
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: ScheduledRevocationBundleStatus) -> Bool {
            switch status {
            case .draft:
                return next == ScheduledRevocationBundleStatus.active
            case .pending:
                return next == ScheduledRevocationBundleStatus.active || next == ScheduledRevocationBundleStatus.closed
            case .active:
                return next == ScheduledRevocationBundleStatus.suspended || next == ScheduledRevocationBundleStatus.closed
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

        func moveTo(_ next: ScheduledRevocationBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled revocation bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled revocation bundle") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(graceDays) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRevocationBundle {
            return ScheduledRevocationBundle(
                code: code,
                title: title,
                sequence: sequence,
                phone: phone,
                description: description,
                region: region,
                graceDays: graceDays,
                dosageMg: dosageMg,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled revocation bundle in status draft.
    static func newScheduledRevocationBundle(_ code: String, title: String) -> ScheduledRevocationBundle {
        return ScheduledRevocationBundle(
            code: code,
            title: title,
            sequence: 0,
            phone: "",
            description: "",
            region: "",
            graceDays: 0,
            dosageMg: 0.0,
            diagnosisCode: "",
            status: ScheduledRevocationBundleStatus.draft
        )
    }
}
