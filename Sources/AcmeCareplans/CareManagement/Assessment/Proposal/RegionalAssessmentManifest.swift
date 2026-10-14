import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional assessment manifest is in its life cycle.
    enum RegionalAssessmentManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional assessment manifest. Its code is unique within a tenant.
    final class RegionalAssessmentManifest {
        var code: String
        var label: String
        var externalRef: String
        var amount: Double
        var pinned: Bool
        var approved: Bool
        var ownerID: String
        var archived: Bool
        var expiresAt: Int
        var status: RegionalAssessmentManifestStatus

        init(code: String, label: String, externalRef: String, amount: Double, pinned: Bool, approved: Bool, ownerID: String, archived: Bool, expiresAt: Int, status: RegionalAssessmentManifestStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.amount = amount
            self.pinned = pinned
            self.approved = approved
            self.ownerID = ownerID
            self.archived = archived
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: RegionalAssessmentManifestStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalAssessmentManifestStatus.inProgress || next == RegionalAssessmentManifestStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalAssessmentManifestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAssessmentManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional assessment manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedLoad() -> Double {
            return (Double(expiresAt) * amount * 100).rounded() / 100
        }

        func copyValue() -> RegionalAssessmentManifest {
            return RegionalAssessmentManifest(
                code: code,
                label: label,
                externalRef: externalRef,
                amount: amount,
                pinned: pinned,
                approved: approved,
                ownerID: ownerID,
                archived: archived,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional assessment manifest in status planned.
    static func newRegionalAssessmentManifest(_ code: String, label: String) -> RegionalAssessmentManifest {
        return RegionalAssessmentManifest(
            code: code,
            label: label,
            externalRef: "",
            amount: 0.0,
            pinned: false,
            approved: false,
            ownerID: "",
            archived: false,
            expiresAt: 0,
            status: RegionalAssessmentManifestStatus.planned
        )
    }
}
