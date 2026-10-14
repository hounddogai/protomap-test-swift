import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census window is in its life cycle.
    enum CensusWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One census window, with what the planners need to act on it.
    final class CensusWindow {
        var code: String
        var name: String
        var floorValue: Double
        var dosageMg: Double
        var facility: String
        var expiresAt: Int
        var allergy: String
        var status: CensusWindowStatus

        init(code: String, name: String, floorValue: Double, dosageMg: Double, facility: String, expiresAt: Int, allergy: String, status: CensusWindowStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.dosageMg = dosageMg
            self.facility = facility
            self.expiresAt = expiresAt
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CensusWindowStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CensusWindowStatus.inProgress || next == CensusWindowStatus.cancelled
            case .inProgress:
                return next == CensusWindowStatus.completed || next == CensusWindowStatus.cancelled
            case .completed:
                return next == CensusWindowStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedLoad() -> Double {
            return (Double(expiresAt) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> CensusWindow {
            return CensusWindow(
                code: code,
                name: name,
                floorValue: floorValue,
                dosageMg: dosageMg,
                facility: facility,
                expiresAt: expiresAt,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a census window in status planned.
    static func newCensusWindow(_ code: String, name: String) -> CensusWindow {
        return CensusWindow(
            code: code,
            name: name,
            floorValue: 0.0,
            dosageMg: 0.0,
            facility: "",
            expiresAt: 0,
            allergy: "",
            status: CensusWindowStatus.planned
        )
    }
}
