import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual outreach record is in its life cycle.
    enum ManualOutreachRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a manual outreach record and its current status.
    final class ManualOutreachRecord {
        var code: String
        var name: String
        var category: String
        var locale: String
        var country: String
        var encounterID: String
        var bed: String
        var score: Double
        var status: ManualOutreachRecordStatus

        init(code: String, name: String, category: String, locale: String, country: String, encounterID: String, bed: String, score: Double, status: ManualOutreachRecordStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.locale = locale
            self.country = country
            self.encounterID = encounterID
            self.bed = bed
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualOutreachRecordStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ManualOutreachRecordStatus.resolved
            case .inReview:
                return next == ManualOutreachRecordStatus.reopened
            case .resolved:
                return next == ManualOutreachRecordStatus.reopened || next == ManualOutreachRecordStatus.archived
            case .reopened:
                return next == ManualOutreachRecordStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualOutreachRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual outreach record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ManualOutreachRecord {
            return ManualOutreachRecord(
                code: code,
                name: name,
                category: category,
                locale: locale,
                country: country,
                encounterID: encounterID,
                bed: bed,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual outreach record in status open.
    static func newManualOutreachRecord(_ code: String, name: String) -> ManualOutreachRecord {
        return ManualOutreachRecord(
            code: code,
            name: name,
            category: "",
            locale: "",
            country: "",
            encounterID: "",
            bed: "",
            score: 0.0,
            status: ManualOutreachRecordStatus.`open`
        )
    }
}
