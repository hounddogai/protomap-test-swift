import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual closure snapshot is in its life cycle.
    enum ManualClosureSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual closure snapshot. Its code is unique within a tenant.
    final class ManualClosureSnapshot {
        var code: String
        var label: String
        var clinicianID: String
        var specialty: String
        var visible: Bool
        var source: String
        var score: Double
        var createdAt: Int
        var quantity: Int
        var windowDays: Int
        var status: ManualClosureSnapshotStatus

        init(code: String, label: String, clinicianID: String, specialty: String, visible: Bool, source: String, score: Double, createdAt: Int, quantity: Int, windowDays: Int, status: ManualClosureSnapshotStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.visible = visible
            self.source = source
            self.score = score
            self.createdAt = createdAt
            self.quantity = quantity
            self.windowDays = windowDays
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

        func canMoveTo(_ next: ManualClosureSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ManualClosureSnapshotStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualClosureSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual closure snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netTotal() -> Double {
            return ((Double(createdAt) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ManualClosureSnapshot {
            return ManualClosureSnapshot(
                code: code,
                label: label,
                clinicianID: clinicianID,
                specialty: specialty,
                visible: visible,
                source: source,
                score: score,
                createdAt: createdAt,
                quantity: quantity,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a manual closure snapshot in status proposed.
    static func newManualClosureSnapshot(_ code: String, label: String) -> ManualClosureSnapshot {
        return ManualClosureSnapshot(
            code: code,
            label: label,
            clinicianID: "",
            specialty: "",
            visible: false,
            source: "",
            score: 0.0,
            createdAt: 0,
            quantity: 0,
            windowDays: 0,
            status: ManualClosureSnapshotStatus.proposed
        )
    }
}
