import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary shift snapshot is in its life cycle.
    enum PrimaryShiftSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One primary shift snapshot, with what the planners need to act on it.
    final class PrimaryShiftSnapshot {
        var code: String
        var title: String
        var description: String
        var budget: Double
        var contactEmail: String
        var procedureCode: String
        var name: String
        var locale: String
        var expiresAt: Int
        var diagnosisCode: String
        var summary: String
        var status: PrimaryShiftSnapshotStatus

        init(code: String, title: String, description: String, budget: Double, contactEmail: String, procedureCode: String, name: String, locale: String, expiresAt: Int, diagnosisCode: String, summary: String, status: PrimaryShiftSnapshotStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.budget = budget
            self.contactEmail = contactEmail
            self.procedureCode = procedureCode
            self.name = name
            self.locale = locale
            self.expiresAt = expiresAt
            self.diagnosisCode = diagnosisCode
            self.summary = summary
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

        func canMoveTo(_ next: PrimaryShiftSnapshotStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryShiftSnapshotStatus.published || next == PrimaryShiftSnapshotStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PrimaryShiftSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary shift snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary shift snapshot") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(expiresAt) * budget * 100).rounded() / 100
        }

        func copyValue() -> PrimaryShiftSnapshot {
            return PrimaryShiftSnapshot(
                code: code,
                title: title,
                description: description,
                budget: budget,
                contactEmail: contactEmail,
                procedureCode: procedureCode,
                name: name,
                locale: locale,
                expiresAt: expiresAt,
                diagnosisCode: diagnosisCode,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a primary shift snapshot in status created.
    static func newPrimaryShiftSnapshot(_ code: String, title: String) -> PrimaryShiftSnapshot {
        return PrimaryShiftSnapshot(
            code: code,
            title: title,
            description: "",
            budget: 0.0,
            contactEmail: "",
            procedureCode: "",
            name: "",
            locale: "",
            expiresAt: 0,
            diagnosisCode: "",
            summary: "",
            status: PrimaryShiftSnapshotStatus.created
        )
    }
}
