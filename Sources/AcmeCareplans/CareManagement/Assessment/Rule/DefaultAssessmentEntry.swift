import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default assessment entry is in its life cycle.
    enum DefaultAssessmentEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default assessment entry. Its code is unique within a tenant.
    final class DefaultAssessmentEntry {
        var code: String
        var name: String
        var tags: [String]
        var graceDays: Int
        var threshold: Double
        var allergy: String
        var status: DefaultAssessmentEntryStatus

        init(code: String, name: String, tags: [String], graceDays: Int, threshold: Double, allergy: String, status: DefaultAssessmentEntryStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.graceDays = graceDays
            self.threshold = threshold
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultAssessmentEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultAssessmentEntryStatus.approved || next == DefaultAssessmentEntryStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DefaultAssessmentEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultAssessmentEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default assessment entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((threshold + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultAssessmentEntry {
            return DefaultAssessmentEntry(
                code: code,
                name: name,
                tags: tags,
                graceDays: graceDays,
                threshold: threshold,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default assessment entry in status proposed.
    static func newDefaultAssessmentEntry(_ code: String, name: String) -> DefaultAssessmentEntry {
        return DefaultAssessmentEntry(
            code: code,
            name: name,
            tags: [],
            graceDays: 0,
            threshold: 0.0,
            allergy: "",
            status: DefaultAssessmentEntryStatus.proposed
        )
    }
}
