import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer group is in its life cycle.
    enum TransferGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A transfer group as the transfer team keeps it.
    final class TransferGroup {
        var code: String
        var name: String
        var pinned: Bool
        var clinicianID: String
        var unit: String
        var copay: Double
        var status: TransferGroupStatus

        init(code: String, name: String, pinned: Bool, clinicianID: String, unit: String, copay: Double, status: TransferGroupStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.unit = unit
            self.copay = copay
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

        func canMoveTo(_ next: TransferGroupStatus) -> Bool {
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
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: TransferGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("transfer group") \(code)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> TransferGroup {
            return TransferGroup(
                code: code,
                name: name,
                pinned: pinned,
                clinicianID: clinicianID,
                unit: unit,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a transfer group in status new.
    static func newTransferGroup(_ code: String, name: String) -> TransferGroup {
        return TransferGroup(
            code: code,
            name: name,
            pinned: false,
            clinicianID: "",
            unit: "",
            copay: 0.0,
            status: TransferGroupStatus.new
        )
    }
}
