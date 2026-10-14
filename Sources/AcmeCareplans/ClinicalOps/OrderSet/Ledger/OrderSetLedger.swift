import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set ledger is in its life cycle.
    enum OrderSetLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A order set ledger. Its code is unique within a tenant.
    final class OrderSetLedger {
        var code: String
        var name: String
        var facility: String
        var sequence: Int
        var floorValue: Double
        var dosageMg: Double
        var channel: String
        var score: Double
        var status: OrderSetLedgerStatus

        init(code: String, name: String, facility: String, sequence: Int, floorValue: Double, dosageMg: Double, channel: String, score: Double, status: OrderSetLedgerStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.sequence = sequence
            self.floorValue = floorValue
            self.dosageMg = dosageMg
            self.channel = channel
            self.score = score
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

        func canMoveTo(_ next: OrderSetLedgerStatus) -> Bool {
            switch status {
            case .requested:
                return next == OrderSetLedgerStatus.revoked
            case .granted:
                return next == OrderSetLedgerStatus.expired
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

        func moveTo(_ next: OrderSetLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("order set ledger") \(code)"
        }

        func projectedExposure() -> Double {
            return ((dosageMg - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetLedger {
            return OrderSetLedger(
                code: code,
                name: name,
                facility: facility,
                sequence: sequence,
                floorValue: floorValue,
                dosageMg: dosageMg,
                channel: channel,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a order set ledger in status requested.
    static func newOrderSetLedger(_ code: String, name: String) -> OrderSetLedger {
        return OrderSetLedger(
            code: code,
            name: name,
            facility: "",
            sequence: 0,
            floorValue: 0.0,
            dosageMg: 0.0,
            channel: "",
            score: 0.0,
            status: OrderSetLedgerStatus.requested
        )
    }
}
