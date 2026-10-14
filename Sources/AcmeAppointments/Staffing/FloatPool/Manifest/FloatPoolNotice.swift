import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool notice is in its life cycle.
    enum FloatPoolNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a float pool notice and its current status.
    final class FloatPoolNotice {
        var code: String
        var title: String
        var patientRef: String
        var active: Bool
        var country: String
        var diagnosisCode: String
        var timezone: String
        var externalRef: String
        var ownerID: String
        var reviewer: String
        var limit: Int
        var status: FloatPoolNoticeStatus

        init(code: String, title: String, patientRef: String, active: Bool, country: String, diagnosisCode: String, timezone: String, externalRef: String, ownerID: String, reviewer: String, limit: Int, status: FloatPoolNoticeStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.active = active
            self.country = country
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.externalRef = externalRef
            self.ownerID = ownerID
            self.reviewer = reviewer
            self.limit = limit
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

        func canMoveTo(_ next: FloatPoolNoticeStatus) -> Bool {
            switch status {
            case .draft:
                return next == FloatPoolNoticeStatus.active || next == FloatPoolNoticeStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == FloatPoolNoticeStatus.suspended || next == FloatPoolNoticeStatus.closed
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

        func moveTo(_ next: FloatPoolNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> FloatPoolNotice {
            return FloatPoolNotice(
                code: code,
                title: title,
                patientRef: patientRef,
                active: active,
                country: country,
                diagnosisCode: diagnosisCode,
                timezone: timezone,
                externalRef: externalRef,
                ownerID: ownerID,
                reviewer: reviewer,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a float pool notice in status draft.
    static func newFloatPoolNotice(_ code: String, title: String) -> FloatPoolNotice {
        return FloatPoolNotice(
            code: code,
            title: title,
            patientRef: "",
            active: false,
            country: "",
            diagnosisCode: "",
            timezone: "",
            externalRef: "",
            ownerID: "",
            reviewer: "",
            limit: 0,
            status: FloatPoolNoticeStatus.draft
        )
    }
}
