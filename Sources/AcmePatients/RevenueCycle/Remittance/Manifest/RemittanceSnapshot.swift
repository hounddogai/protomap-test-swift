import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance snapshot is in its life cycle.
    enum RemittanceSnapshotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a remittance snapshot and its current status.
    final class RemittanceSnapshot {
        var code: String
        var name: String
        var dosageMg: Double
        var expiresAt: Int
        var facility: String
        var visitMinutes: Int
        var visible: Bool
        var country: String
        var status: RemittanceSnapshotStatus

        init(code: String, name: String, dosageMg: Double, expiresAt: Int, facility: String, visitMinutes: Int, visible: Bool, country: String, status: RemittanceSnapshotStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.expiresAt = expiresAt
            self.facility = facility
            self.visitMinutes = visitMinutes
            self.visible = visible
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RemittanceSnapshotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RemittanceSnapshotStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RemittanceSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netLoad() -> Double {
            return (dosageMg * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceSnapshot {
            return RemittanceSnapshot(
                code: code,
                name: name,
                dosageMg: dosageMg,
                expiresAt: expiresAt,
                facility: facility,
                visitMinutes: visitMinutes,
                visible: visible,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a remittance snapshot in status idle.
    static func newRemittanceSnapshot(_ code: String, name: String) -> RemittanceSnapshot {
        return RemittanceSnapshot(
            code: code,
            name: name,
            dosageMg: 0.0,
            expiresAt: 0,
            facility: "",
            visitMinutes: 0,
            visible: false,
            country: "",
            status: RemittanceSnapshotStatus.idle
        )
    }
}
