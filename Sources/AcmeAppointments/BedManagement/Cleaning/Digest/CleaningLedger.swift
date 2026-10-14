import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning ledger is in its life cycle.
    enum CleaningLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A cleaning ledger. Its code is unique within a tenant.
    final class CleaningLedger {
        var code: String
        var label: String
        var unit: String
        var name: String
        var capacity: Int
        var floorValue: Double
        var checksum: String
        var ward: String
        var dosageMg: Double
        var externalRef: String
        var status: CleaningLedgerStatus

        init(code: String, label: String, unit: String, name: String, capacity: Int, floorValue: Double, checksum: String, ward: String, dosageMg: Double, externalRef: String, status: CleaningLedgerStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.name = name
            self.capacity = capacity
            self.floorValue = floorValue
            self.checksum = checksum
            self.ward = ward
            self.dosageMg = dosageMg
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CleaningLedgerStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CleaningLedgerStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CleaningLedgerStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return (Double(capacity) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> CleaningLedger {
            return CleaningLedger(
                code: code,
                label: label,
                unit: unit,
                name: name,
                capacity: capacity,
                floorValue: floorValue,
                checksum: checksum,
                ward: ward,
                dosageMg: dosageMg,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a cleaning ledger in status new.
    static func newCleaningLedger(_ code: String, label: String) -> CleaningLedger {
        return CleaningLedger(
            code: code,
            label: label,
            unit: "",
            name: "",
            capacity: 0,
            floorValue: 0.0,
            checksum: "",
            ward: "",
            dosageMg: 0.0,
            externalRef: "",
            status: CleaningLedgerStatus.new
        )
    }
}
