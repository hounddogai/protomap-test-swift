import AcmePlatform
import Foundation

extension Consent {
    /// Where a language baseline is in its life cycle.
    enum LanguageBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A language baseline. Its code is unique within a tenant.
    final class LanguageBaseline {
        var code: String
        var name: String
        var limit: Int
        var patientRef: String
        var summary: String
        var region: String
        var contactEmail: String
        var clinicianID: String
        var status: LanguageBaselineStatus

        init(code: String, name: String, limit: Int, patientRef: String, summary: String, region: String, contactEmail: String, clinicianID: String, status: LanguageBaselineStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.patientRef = patientRef
            self.summary = summary
            self.region = region
            self.contactEmail = contactEmail
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LanguageBaselineStatus) -> Bool {
            switch status {
            case .planned:
                return next == LanguageBaselineStatus.inProgress || next == LanguageBaselineStatus.cancelled
            case .scheduled:
                return next == LanguageBaselineStatus.completed
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LanguageBaselineStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> LanguageBaseline {
            return LanguageBaseline(
                code: code,
                name: name,
                limit: limit,
                patientRef: patientRef,
                summary: summary,
                region: region,
                contactEmail: contactEmail,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a language baseline in status planned.
    static func newLanguageBaseline(_ code: String, name: String) -> LanguageBaseline {
        return LanguageBaseline(
            code: code,
            name: name,
            limit: 0,
            patientRef: "",
            summary: "",
            region: "",
            contactEmail: "",
            clinicianID: "",
            status: LanguageBaselineStatus.planned
        )
    }
}
