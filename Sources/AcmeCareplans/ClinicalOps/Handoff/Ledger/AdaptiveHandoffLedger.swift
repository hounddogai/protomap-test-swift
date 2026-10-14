import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive handoff ledger is in its life cycle.
    enum AdaptiveHandoffLedgerStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive handoff ledger as the handoff team keeps it.
    final class AdaptiveHandoffLedger {
        var code: String
        var title: String
        var floorValue: Double
        var unit: String
        var procedureCode: String
        var facility: String
        var region: String
        var notes: String
        var acuity: Int
        var status: AdaptiveHandoffLedgerStatus

        init(code: String, title: String, floorValue: Double, unit: String, procedureCode: String, facility: String, region: String, notes: String, acuity: Int, status: AdaptiveHandoffLedgerStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.unit = unit
            self.procedureCode = procedureCode
            self.facility = facility
            self.region = region
            self.notes = notes
            self.acuity = acuity
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

        func canMoveTo(_ next: AdaptiveHandoffLedgerStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: AdaptiveHandoffLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive handoff ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return ((Double(acuity) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveHandoffLedger {
            return AdaptiveHandoffLedger(
                code: code,
                title: title,
                floorValue: floorValue,
                unit: unit,
                procedureCode: procedureCode,
                facility: facility,
                region: region,
                notes: notes,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive handoff ledger in status proposed.
    static func newAdaptiveHandoffLedger(_ code: String, title: String) -> AdaptiveHandoffLedger {
        return AdaptiveHandoffLedger(
            code: code,
            title: title,
            floorValue: 0.0,
            unit: "",
            procedureCode: "",
            facility: "",
            region: "",
            notes: "",
            acuity: 0,
            status: AdaptiveHandoffLedgerStatus.proposed
        )
    }
}
