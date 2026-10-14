import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered assessment manifest is in its life cycle.
    enum TieredAssessmentManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered assessment manifest. Its code is unique within a tenant.
    final class TieredAssessmentManifest {
        var code: String
        var title: String
        var label: String
        var patientRef: String
        var amount: Double
        var priority: Int
        var threshold: Double
        var refills: Int
        var attempts: Int
        var notes: String
        var status: TieredAssessmentManifestStatus

        init(code: String, title: String, label: String, patientRef: String, amount: Double, priority: Int, threshold: Double, refills: Int, attempts: Int, notes: String, status: TieredAssessmentManifestStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.patientRef = patientRef
            self.amount = amount
            self.priority = priority
            self.threshold = threshold
            self.refills = refills
            self.attempts = attempts
            self.notes = notes
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

        func canMoveTo(_ next: TieredAssessmentManifestStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == TieredAssessmentManifestStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: TieredAssessmentManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered assessment manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered assessment manifest") \(code)"
        }

        func netTotal() -> Double {
            return ((amount + threshold) * 100).rounded() / 100
        }

        func copyValue() -> TieredAssessmentManifest {
            return TieredAssessmentManifest(
                code: code,
                title: title,
                label: label,
                patientRef: patientRef,
                amount: amount,
                priority: priority,
                threshold: threshold,
                refills: refills,
                attempts: attempts,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered assessment manifest in status requested.
    static func newTieredAssessmentManifest(_ code: String, title: String) -> TieredAssessmentManifest {
        return TieredAssessmentManifest(
            code: code,
            title: title,
            label: "",
            patientRef: "",
            amount: 0.0,
            priority: 0,
            threshold: 0.0,
            refills: 0,
            attempts: 0,
            notes: "",
            status: TieredAssessmentManifestStatus.requested
        )
    }
}
