import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation snapshot is in its life cycle.
    enum RevocationSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One revocation snapshot, with what the planners need to act on it.
    final class RevocationSnapshot {
        var code: String
        var title: String
        var pinned: Bool
        var payer: String
        var quantity: Int
        var patientRef: String
        var approved: Bool
        var acuity: Int
        var checksum: String
        var name: String
        var visitMinutes: Int
        var status: RevocationSnapshotStatus

        init(code: String, title: String, pinned: Bool, payer: String, quantity: Int, patientRef: String, approved: Bool, acuity: Int, checksum: String, name: String, visitMinutes: Int, status: RevocationSnapshotStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.payer = payer
            self.quantity = quantity
            self.patientRef = patientRef
            self.approved = approved
            self.acuity = acuity
            self.checksum = checksum
            self.name = name
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: RevocationSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RevocationSnapshotStatus.approved || next == RevocationSnapshotStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RevocationSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return ((Double(quantity) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationSnapshot {
            return RevocationSnapshot(
                code: code,
                title: title,
                pinned: pinned,
                payer: payer,
                quantity: quantity,
                patientRef: patientRef,
                approved: approved,
                acuity: acuity,
                checksum: checksum,
                name: name,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a revocation snapshot in status proposed.
    static func newRevocationSnapshot(_ code: String, title: String) -> RevocationSnapshot {
        return RevocationSnapshot(
            code: code,
            title: title,
            pinned: false,
            payer: "",
            quantity: 0,
            patientRef: "",
            approved: false,
            acuity: 0,
            checksum: "",
            name: "",
            visitMinutes: 0,
            status: RevocationSnapshotStatus.proposed
        )
    }
}
