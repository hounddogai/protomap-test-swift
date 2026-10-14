import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped network record is in its life cycle.
    enum CappedNetworkRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped network record. Its code is unique within a tenant.
    final class CappedNetworkRecord {
        var code: String
        var name: String
        var facility: String
        var procedureCode: String
        var dosageMg: Double
        var ownerID: String
        var pinned: Bool
        var checksum: String
        var status: CappedNetworkRecordStatus

        init(code: String, name: String, facility: String, procedureCode: String, dosageMg: Double, ownerID: String, pinned: Bool, checksum: String, status: CappedNetworkRecordStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.procedureCode = procedureCode
            self.dosageMg = dosageMg
            self.ownerID = ownerID
            self.pinned = pinned
            self.checksum = checksum
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

        func canMoveTo(_ next: CappedNetworkRecordStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
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
                return next == CappedNetworkRecordStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedNetworkRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped network record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> CappedNetworkRecord {
            return CappedNetworkRecord(
                code: code,
                name: name,
                facility: facility,
                procedureCode: procedureCode,
                dosageMg: dosageMg,
                ownerID: ownerID,
                pinned: pinned,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a capped network record in status proposed.
    static func newCappedNetworkRecord(_ code: String, name: String) -> CappedNetworkRecord {
        return CappedNetworkRecord(
            code: code,
            name: name,
            facility: "",
            procedureCode: "",
            dosageMg: 0.0,
            ownerID: "",
            pinned: false,
            checksum: "",
            status: CappedNetworkRecordStatus.proposed
        )
    }
}
