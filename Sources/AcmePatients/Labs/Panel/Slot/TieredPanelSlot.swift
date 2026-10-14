import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered panel slot is in its life cycle.
    enum TieredPanelSlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered panel slot as the panel team keeps it.
    final class TieredPanelSlot {
        var code: String
        var label: String
        var checksum: String
        var encounterID: String
        var cost: Double
        var status: TieredPanelSlotStatus

        init(code: String, label: String, checksum: String, encounterID: String, cost: Double, status: TieredPanelSlotStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.encounterID = encounterID
            self.cost = cost
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

        func canMoveTo(_ next: TieredPanelSlotStatus) -> Bool {
            switch status {
            case .idle:
                return next == TieredPanelSlotStatus.ready
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TieredPanelSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered panel slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> TieredPanelSlot {
            return TieredPanelSlot(
                code: code,
                label: label,
                checksum: checksum,
                encounterID: encounterID,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered panel slot in status idle.
    static func newTieredPanelSlot(_ code: String, label: String) -> TieredPanelSlot {
        return TieredPanelSlot(
            code: code,
            label: label,
            checksum: "",
            encounterID: "",
            cost: 0.0,
            status: TieredPanelSlotStatus.idle
        )
    }
}
