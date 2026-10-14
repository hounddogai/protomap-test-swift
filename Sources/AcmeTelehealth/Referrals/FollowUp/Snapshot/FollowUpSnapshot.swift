import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up snapshot is in its life cycle.
    enum FollowUpSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A follow up snapshot. Its code is unique within a tenant.
    final class FollowUpSnapshot {
        var code: String
        var label: String
        var quantity: Int
        var acuity: Int
        var procedureCode: String
        var patientRef: String
        var expiresAt: Int
        var unit: String
        var archived: Bool
        var status: FollowUpSnapshotStatus

        init(code: String, label: String, quantity: Int, acuity: Int, procedureCode: String, patientRef: String, expiresAt: Int, unit: String, archived: Bool, status: FollowUpSnapshotStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.acuity = acuity
            self.procedureCode = procedureCode
            self.patientRef = patientRef
            self.expiresAt = expiresAt
            self.unit = unit
            self.archived = archived
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

        func canMoveTo(_ next: FollowUpSnapshotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == FollowUpSnapshotStatus.running || next == FollowUpSnapshotStatus.done
            case .running:
                return next == FollowUpSnapshotStatus.failed
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

        func moveTo(_ next: FollowUpSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedVolume() -> Double {
            return ((Double(expiresAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpSnapshot {
            return FollowUpSnapshot(
                code: code,
                label: label,
                quantity: quantity,
                acuity: acuity,
                procedureCode: procedureCode,
                patientRef: patientRef,
                expiresAt: expiresAt,
                unit: unit,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a follow up snapshot in status new.
    static func newFollowUpSnapshot(_ code: String, label: String) -> FollowUpSnapshot {
        return FollowUpSnapshot(
            code: code,
            label: label,
            quantity: 0,
            acuity: 0,
            procedureCode: "",
            patientRef: "",
            expiresAt: 0,
            unit: "",
            archived: false,
            status: FollowUpSnapshotStatus.new
        )
    }
}
