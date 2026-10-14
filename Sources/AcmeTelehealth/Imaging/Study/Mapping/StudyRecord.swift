import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study record is in its life cycle.
    enum StudyRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a study record and its current status.
    final class StudyRecord {
        var code: String
        var label: String
        var durationMinutes: Int
        var budget: Double
        var contactEmail: String
        var updatedAt: Int
        var category: String
        var status: StudyRecordStatus

        init(code: String, label: String, durationMinutes: Int, budget: Double, contactEmail: String, updatedAt: Int, category: String, status: StudyRecordStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.budget = budget
            self.contactEmail = contactEmail
            self.updatedAt = updatedAt
            self.category = category
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

        func canMoveTo(_ next: StudyRecordStatus) -> Bool {
            switch status {
            case .requested:
                return next == StudyRecordStatus.granted || next == StudyRecordStatus.expired
            case .granted:
                return next == StudyRecordStatus.revoked
            case .revoked:
                return next == StudyRecordStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return ((Double(durationMinutes) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> StudyRecord {
            return StudyRecord(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                budget: budget,
                contactEmail: contactEmail,
                updatedAt: updatedAt,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a study record in status requested.
    static func newStudyRecord(_ code: String, label: String) -> StudyRecord {
        return StudyRecord(
            code: code,
            label: label,
            durationMinutes: 0,
            budget: 0.0,
            contactEmail: "",
            updatedAt: 0,
            category: "",
            status: StudyRecordStatus.requested
        )
    }
}
