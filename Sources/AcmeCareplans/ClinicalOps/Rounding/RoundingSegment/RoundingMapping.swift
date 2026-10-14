import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding mapping is in its life cycle.
    enum RoundingMappingStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One rounding mapping, with what the planners need to act on it.
    final class RoundingMapping {
        var code: String
        var name: String
        var procedureCode: String
        var diagnosisCode: String
        var visitMinutes: Int
        var capacity: Int
        var phone: String
        var status: RoundingMappingStatus

        init(code: String, name: String, procedureCode: String, diagnosisCode: String, visitMinutes: Int, capacity: Int, phone: String, status: RoundingMappingStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.diagnosisCode = diagnosisCode
            self.visitMinutes = visitMinutes
            self.capacity = capacity
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RoundingMappingStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RoundingMappingStatus.reopened || next == RoundingMappingStatus.archived
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RoundingMappingStatus.reopened || next == RoundingMappingStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RoundingMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedValue() -> Double {
            return ((Double(capacity) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingMapping {
            return RoundingMapping(
                code: code,
                name: name,
                procedureCode: procedureCode,
                diagnosisCode: diagnosisCode,
                visitMinutes: visitMinutes,
                capacity: capacity,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding mapping in status open.
    static func newRoundingMapping(_ code: String, name: String) -> RoundingMapping {
        return RoundingMapping(
            code: code,
            name: name,
            procedureCode: "",
            diagnosisCode: "",
            visitMinutes: 0,
            capacity: 0,
            phone: "",
            status: RoundingMappingStatus.`open`
        )
    }
}
