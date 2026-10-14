import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary slot manifest is in its life cycle.
    enum PrimarySlotManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary slot manifest as the slot team keeps it.
    final class PrimarySlotManifest {
        var code: String
        var title: String
        var dosageMg: Double
        var threshold: Double
        var encounterID: String
        var notes: String
        var amount: Double
        var visitMinutes: Int
        var ceiling: Double
        var copay: Double
        var status: PrimarySlotManifestStatus

        init(code: String, title: String, dosageMg: Double, threshold: Double, encounterID: String, notes: String, amount: Double, visitMinutes: Int, ceiling: Double, copay: Double, status: PrimarySlotManifestStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.threshold = threshold
            self.encounterID = encounterID
            self.notes = notes
            self.amount = amount
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.copay = copay
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

        func canMoveTo(_ next: PrimarySlotManifestStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimarySlotManifestStatus.active || next == PrimarySlotManifestStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: PrimarySlotManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary slot manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary slot manifest") \(code)"
        }

        func weightedTotal() -> Double {
            return ((amount + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySlotManifest {
            return PrimarySlotManifest(
                code: code,
                title: title,
                dosageMg: dosageMg,
                threshold: threshold,
                encounterID: encounterID,
                notes: notes,
                amount: amount,
                visitMinutes: visitMinutes,
                ceiling: ceiling,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary slot manifest in status draft.
    static func newPrimarySlotManifest(_ code: String, title: String) -> PrimarySlotManifest {
        return PrimarySlotManifest(
            code: code,
            title: title,
            dosageMg: 0.0,
            threshold: 0.0,
            encounterID: "",
            notes: "",
            amount: 0.0,
            visitMinutes: 0,
            ceiling: 0.0,
            copay: 0.0,
            status: PrimarySlotManifestStatus.draft
        )
    }
}
