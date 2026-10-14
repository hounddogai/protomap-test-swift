import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy assessment rollup is in its life cycle.
    enum LegacyAssessmentRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A legacy assessment rollup. Its code is unique within a tenant.
    final class LegacyAssessmentRollup {
        var code: String
        var label: String
        var weight: Double
        var description: String
        var contactEmail: String
        var ownerID: String
        var title: String
        var status: LegacyAssessmentRollupStatus

        init(code: String, label: String, weight: Double, description: String, contactEmail: String, ownerID: String, title: String, status: LegacyAssessmentRollupStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.description = description
            self.contactEmail = contactEmail
            self.ownerID = ownerID
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyAssessmentRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyAssessmentRollupStatus.running || next == LegacyAssessmentRollupStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: LegacyAssessmentRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy assessment rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> LegacyAssessmentRollup {
            return LegacyAssessmentRollup(
                code: code,
                label: label,
                weight: weight,
                description: description,
                contactEmail: contactEmail,
                ownerID: ownerID,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy assessment rollup in status new.
    static func newLegacyAssessmentRollup(_ code: String, label: String) -> LegacyAssessmentRollup {
        return LegacyAssessmentRollup(
            code: code,
            label: label,
            weight: 0.0,
            description: "",
            contactEmail: "",
            ownerID: "",
            title: "",
            status: LegacyAssessmentRollupStatus.new
        )
    }
}
