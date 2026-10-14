import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form slot is in its life cycle.
    enum ConsentFormSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a consent form slot and its current status.
    final class ConsentFormSlot {
        var code: String
        var name: String
        var dosageMg: Double
        var checksum: String
        var payer: String
        var status: ConsentFormSlotStatus

        init(code: String, name: String, dosageMg: Double, checksum: String, payer: String, status: ConsentFormSlotStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.checksum = checksum
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormSlotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ConsentFormSlotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> ConsentFormSlot {
            return ConsentFormSlot(
                code: code,
                name: name,
                dosageMg: dosageMg,
                checksum: checksum,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a consent form slot in status created.
    static func newConsentFormSlot(_ code: String, name: String) -> ConsentFormSlot {
        return ConsentFormSlot(
            code: code,
            name: name,
            dosageMg: 0.0,
            checksum: "",
            payer: "",
            status: ConsentFormSlotStatus.created
        )
    }
}
