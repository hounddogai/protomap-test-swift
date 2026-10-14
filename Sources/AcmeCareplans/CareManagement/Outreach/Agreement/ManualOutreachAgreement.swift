import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual outreach agreement is in its life cycle.
    enum ManualOutreachAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual outreach agreement as the outreach team keeps it.
    final class ManualOutreachAgreement {
        var code: String
        var label: String
        var version: Int
        var floorValue: Double
        var procedureCode: String
        var rate: Double
        var title: String
        var windowDays: Int
        var retries: Int
        var reviewer: String
        var score: Double
        var status: ManualOutreachAgreementStatus

        init(code: String, label: String, version: Int, floorValue: Double, procedureCode: String, rate: Double, title: String, windowDays: Int, retries: Int, reviewer: String, score: Double, status: ManualOutreachAgreementStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.floorValue = floorValue
            self.procedureCode = procedureCode
            self.rate = rate
            self.title = title
            self.windowDays = windowDays
            self.retries = retries
            self.reviewer = reviewer
            self.score = score
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

        func canMoveTo(_ next: ManualOutreachAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == ManualOutreachAgreementStatus.pending || next == ManualOutreachAgreementStatus.active
            case .pending:
                return next == ManualOutreachAgreementStatus.suspended || next == ManualOutreachAgreementStatus.closed
            case .active:
                return next == ManualOutreachAgreementStatus.suspended
            case .suspended:
                return next == ManualOutreachAgreementStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualOutreachAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual outreach agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedLoad() -> Double {
            return ((floorValue - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ManualOutreachAgreement {
            return ManualOutreachAgreement(
                code: code,
                label: label,
                version: version,
                floorValue: floorValue,
                procedureCode: procedureCode,
                rate: rate,
                title: title,
                windowDays: windowDays,
                retries: retries,
                reviewer: reviewer,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual outreach agreement in status draft.
    static func newManualOutreachAgreement(_ code: String, label: String) -> ManualOutreachAgreement {
        return ManualOutreachAgreement(
            code: code,
            label: label,
            version: 0,
            floorValue: 0.0,
            procedureCode: "",
            rate: 0.0,
            title: "",
            windowDays: 0,
            retries: 0,
            reviewer: "",
            score: 0.0,
            status: ManualOutreachAgreementStatus.draft
        )
    }
}
