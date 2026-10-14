import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal handoff window is in its life cycle.
    enum SeasonalHandoffWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal handoff window. Its code is unique within a tenant.
    final class SeasonalHandoffWindow {
        var code: String
        var label: String
        var sequence: Int
        var capacity: Int
        var notes: String
        var createdAt: Int
        var floorValue: Double
        var procedureCode: String
        var status: SeasonalHandoffWindowStatus

        init(code: String, label: String, sequence: Int, capacity: Int, notes: String, createdAt: Int, floorValue: Double, procedureCode: String, status: SeasonalHandoffWindowStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.capacity = capacity
            self.notes = notes
            self.createdAt = createdAt
            self.floorValue = floorValue
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: SeasonalHandoffWindowStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SeasonalHandoffWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal handoff window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("seasonal handoff window") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(createdAt) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalHandoffWindow {
            return SeasonalHandoffWindow(
                code: code,
                label: label,
                sequence: sequence,
                capacity: capacity,
                notes: notes,
                createdAt: createdAt,
                floorValue: floorValue,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal handoff window in status requested.
    static func newSeasonalHandoffWindow(_ code: String, label: String) -> SeasonalHandoffWindow {
        return SeasonalHandoffWindow(
            code: code,
            label: label,
            sequence: 0,
            capacity: 0,
            notes: "",
            createdAt: 0,
            floorValue: 0.0,
            procedureCode: "",
            status: SeasonalHandoffWindowStatus.requested
        )
    }
}
