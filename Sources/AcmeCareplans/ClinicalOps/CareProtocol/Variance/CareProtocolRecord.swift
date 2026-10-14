import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol record is in its life cycle.
    enum CareProtocolRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One care protocol record, with what the planners need to act on it.
    final class CareProtocolRecord {
        var code: String
        var name: String
        var refills: Int
        var patientRef: String
        var endsAt: Int
        var status: CareProtocolRecordStatus

        init(code: String, name: String, refills: Int, patientRef: String, endsAt: Int, status: CareProtocolRecordStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.patientRef = patientRef
            self.endsAt = endsAt
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

        func canMoveTo(_ next: CareProtocolRecordStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CareProtocolRecordStatus.rejected
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

        func moveTo(_ next: CareProtocolRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedTotal() -> Double {
            return (Double(refills) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolRecord {
            return CareProtocolRecord(
                code: code,
                name: name,
                refills: refills,
                patientRef: patientRef,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol record in status proposed.
    static func newCareProtocolRecord(_ code: String, name: String) -> CareProtocolRecord {
        return CareProtocolRecord(
            code: code,
            name: name,
            refills: 0,
            patientRef: "",
            endsAt: 0,
            status: CareProtocolRecordStatus.proposed
        )
    }
}
