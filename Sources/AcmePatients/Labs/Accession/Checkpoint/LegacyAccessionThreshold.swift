import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy accession threshold is in its life cycle.
    enum LegacyAccessionThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy accession threshold as the accession team keeps it.
    final class LegacyAccessionThreshold {
        var code: String
        var label: String
        var createdAt: Int
        var clinicianID: String
        var patientRef: String
        var externalRef: String
        var pinned: Bool
        var copay: Double
        var active: Bool
        var discount: Double
        var status: LegacyAccessionThresholdStatus

        init(code: String, label: String, createdAt: Int, clinicianID: String, patientRef: String, externalRef: String, pinned: Bool, copay: Double, active: Bool, discount: Double, status: LegacyAccessionThresholdStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.clinicianID = clinicianID
            self.patientRef = patientRef
            self.externalRef = externalRef
            self.pinned = pinned
            self.copay = copay
            self.active = active
            self.discount = discount
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

        func canMoveTo(_ next: LegacyAccessionThresholdStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LegacyAccessionThresholdStatus.active
            case .active:
                return next == LegacyAccessionThresholdStatus.suspended || next == LegacyAccessionThresholdStatus.closed
            case .suspended:
                return next == LegacyAccessionThresholdStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAccessionThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy accession threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return ((discount + copay) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAccessionThreshold {
            return LegacyAccessionThreshold(
                code: code,
                label: label,
                createdAt: createdAt,
                clinicianID: clinicianID,
                patientRef: patientRef,
                externalRef: externalRef,
                pinned: pinned,
                copay: copay,
                active: active,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy accession threshold in status draft.
    static func newLegacyAccessionThreshold(_ code: String, label: String) -> LegacyAccessionThreshold {
        return LegacyAccessionThreshold(
            code: code,
            label: label,
            createdAt: 0,
            clinicianID: "",
            patientRef: "",
            externalRef: "",
            pinned: false,
            copay: 0.0,
            active: false,
            discount: 0.0,
            status: LegacyAccessionThresholdStatus.draft
        )
    }
}
