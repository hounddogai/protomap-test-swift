import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program snapshot is in its life cycle.
    enum ProgramSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A program snapshot as the program team keeps it.
    final class ProgramSnapshot {
        var code: String
        var label: String
        var cost: Double
        var endsAt: Int
        var unit: String
        var acuity: Int
        var version: Int
        var status: ProgramSnapshotStatus

        init(code: String, label: String, cost: Double, endsAt: Int, unit: String, acuity: Int, version: Int, status: ProgramSnapshotStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.endsAt = endsAt
            self.unit = unit
            self.acuity = acuity
            self.version = version
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

        func canMoveTo(_ next: ProgramSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ProgramSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedLoad() -> Double {
            return ((cost + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramSnapshot {
            return ProgramSnapshot(
                code: code,
                label: label,
                cost: cost,
                endsAt: endsAt,
                unit: unit,
                acuity: acuity,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a program snapshot in status requested.
    static func newProgramSnapshot(_ code: String, label: String) -> ProgramSnapshot {
        return ProgramSnapshot(
            code: code,
            label: label,
            cost: 0.0,
            endsAt: 0,
            unit: "",
            acuity: 0,
            version: 0,
            status: ProgramSnapshotStatus.requested
        )
    }
}
