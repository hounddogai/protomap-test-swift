import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board cycle is in its life cycle.
    enum BedBoardCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a bed board cycle and its current status.
    final class BedBoardCycle {
        var code: String
        var name: String
        var notes: String
        var expiresAt: Int
        var ceiling: Double
        var region: String
        var visible: Bool
        var facility: String
        var source: String
        var status: BedBoardCycleStatus

        init(code: String, name: String, notes: String, expiresAt: Int, ceiling: Double, region: String, visible: Bool, facility: String, source: String, status: BedBoardCycleStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.expiresAt = expiresAt
            self.ceiling = ceiling
            self.region = region
            self.visible = visible
            self.facility = facility
            self.source = source
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

        func canMoveTo(_ next: BedBoardCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == BedBoardCycleStatus.published || next == BedBoardCycleStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: BedBoardCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedValue() -> Double {
            return (ceiling * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardCycle {
            return BedBoardCycle(
                code: code,
                name: name,
                notes: notes,
                expiresAt: expiresAt,
                ceiling: ceiling,
                region: region,
                visible: visible,
                facility: facility,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a bed board cycle in status created.
    static func newBedBoardCycle(_ code: String, name: String) -> BedBoardCycle {
        return BedBoardCycle(
            code: code,
            name: name,
            notes: "",
            expiresAt: 0,
            ceiling: 0.0,
            region: "",
            visible: false,
            facility: "",
            source: "",
            status: BedBoardCycleStatus.created
        )
    }
}
