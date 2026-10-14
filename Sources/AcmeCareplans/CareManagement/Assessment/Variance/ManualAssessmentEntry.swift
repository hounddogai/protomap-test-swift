import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual assessment entry is in its life cycle.
    enum ManualAssessmentEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual assessment entry as the assessment team keeps it.
    final class ManualAssessmentEntry {
        var code: String
        var title: String
        var contactEmail: String
        var quantity: Int
        var summary: String
        var batchSize: Int
        var tags: [String]
        var visible: Bool
        var minimum: Double
        var status: ManualAssessmentEntryStatus

        init(code: String, title: String, contactEmail: String, quantity: Int, summary: String, batchSize: Int, tags: [String], visible: Bool, minimum: Double, status: ManualAssessmentEntryStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.quantity = quantity
            self.summary = summary
            self.batchSize = batchSize
            self.tags = tags
            self.visible = visible
            self.minimum = minimum
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

        func canMoveTo(_ next: ManualAssessmentEntryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ManualAssessmentEntryStatus.active || next == ManualAssessmentEntryStatus.suspended
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualAssessmentEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual assessment entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return ((minimum - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ManualAssessmentEntry {
            return ManualAssessmentEntry(
                code: code,
                title: title,
                contactEmail: contactEmail,
                quantity: quantity,
                summary: summary,
                batchSize: batchSize,
                tags: tags,
                visible: visible,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual assessment entry in status draft.
    static func newManualAssessmentEntry(_ code: String, title: String) -> ManualAssessmentEntry {
        return ManualAssessmentEntry(
            code: code,
            title: title,
            contactEmail: "",
            quantity: 0,
            summary: "",
            batchSize: 0,
            tags: [],
            visible: false,
            minimum: 0.0,
            status: ManualAssessmentEntryStatus.draft
        )
    }
}
