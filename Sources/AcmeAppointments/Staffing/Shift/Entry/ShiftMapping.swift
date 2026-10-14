import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift mapping is in its life cycle.
    enum ShiftMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a shift mapping and its current status.
    final class ShiftMapping {
        var code: String
        var name: String
        var refills: Int
        var sequence: Int
        var procedureCode: String
        var status: ShiftMappingStatus

        init(code: String, name: String, refills: Int, sequence: Int, procedureCode: String, status: ShiftMappingStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.sequence = sequence
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftMappingStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ShiftMappingStatus.active
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ShiftMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedLoad() -> Double {
            return (Double(sequence) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> ShiftMapping {
            return ShiftMapping(
                code: code,
                name: name,
                refills: refills,
                sequence: sequence,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a shift mapping in status draft.
    static func newShiftMapping(_ code: String, name: String) -> ShiftMapping {
        return ShiftMapping(
            code: code,
            name: name,
            refills: 0,
            sequence: 0,
            procedureCode: "",
            status: ShiftMappingStatus.draft
        )
    }
}
