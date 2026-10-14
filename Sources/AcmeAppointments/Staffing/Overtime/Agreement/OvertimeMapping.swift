import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime mapping is in its life cycle.
    enum OvertimeMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a overtime mapping and its current status.
    final class OvertimeMapping {
        var code: String
        var title: String
        var sequence: Int
        var procedureCode: String
        var copay: Double
        var updatedAt: Int
        var status: OvertimeMappingStatus

        init(code: String, title: String, sequence: Int, procedureCode: String, copay: Double, updatedAt: Int, status: OvertimeMappingStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.procedureCode = procedureCode
            self.copay = copay
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: OvertimeMappingStatus) -> Bool {
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

        func moveTo(_ next: OvertimeMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(sequence) - copay) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeMapping {
            return OvertimeMapping(
                code: code,
                title: title,
                sequence: sequence,
                procedureCode: procedureCode,
                copay: copay,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a overtime mapping in status created.
    static func newOvertimeMapping(_ code: String, title: String) -> OvertimeMapping {
        return OvertimeMapping(
            code: code,
            title: title,
            sequence: 0,
            procedureCode: "",
            copay: 0.0,
            updatedAt: 0,
            status: OvertimeMappingStatus.created
        )
    }
}
