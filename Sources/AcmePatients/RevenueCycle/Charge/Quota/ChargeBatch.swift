import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge batch is in its life cycle.
    enum ChargeBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A charge batch as the charge team keeps it.
    final class ChargeBatch {
        var code: String
        var name: String
        var segment: String
        var phone: String
        var clinicianID: String
        var externalRef: String
        var channel: String
        var bed: String
        var copay: Double
        var procedureCode: String
        var sequence: Int
        var status: ChargeBatchStatus

        init(code: String, name: String, segment: String, phone: String, clinicianID: String, externalRef: String, channel: String, bed: String, copay: Double, procedureCode: String, sequence: Int, status: ChargeBatchStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.phone = phone
            self.clinicianID = clinicianID
            self.externalRef = externalRef
            self.channel = channel
            self.bed = bed
            self.copay = copay
            self.procedureCode = procedureCode
            self.sequence = sequence
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

        func canMoveTo(_ next: ChargeBatchStatus) -> Bool {
            switch status {
            case .requested:
                return next == ChargeBatchStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ChargeBatchStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return ((Double(sequence) + copay) * 100).rounded() / 100
        }

        func copyValue() -> ChargeBatch {
            return ChargeBatch(
                code: code,
                name: name,
                segment: segment,
                phone: phone,
                clinicianID: clinicianID,
                externalRef: externalRef,
                channel: channel,
                bed: bed,
                copay: copay,
                procedureCode: procedureCode,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a charge batch in status requested.
    static func newChargeBatch(_ code: String, name: String) -> ChargeBatch {
        return ChargeBatch(
            code: code,
            name: name,
            segment: "",
            phone: "",
            clinicianID: "",
            externalRef: "",
            channel: "",
            bed: "",
            copay: 0.0,
            procedureCode: "",
            sequence: 0,
            status: ChargeBatchStatus.requested
        )
    }
}
