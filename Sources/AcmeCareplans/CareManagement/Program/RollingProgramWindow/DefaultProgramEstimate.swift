import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default program estimate is in its life cycle.
    enum DefaultProgramEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default program estimate. Its code is unique within a tenant.
    final class DefaultProgramEstimate {
        var code: String
        var name: String
        var segment: String
        var summary: String
        var procedureCode: String
        var specialty: String
        var quantity: Int
        var status: DefaultProgramEstimateStatus

        init(code: String, name: String, segment: String, summary: String, procedureCode: String, specialty: String, quantity: Int, status: DefaultProgramEstimateStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.summary = summary
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.quantity = quantity
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

        func canMoveTo(_ next: DefaultProgramEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DefaultProgramEstimateStatus.rejected || next == DefaultProgramEstimateStatus.withdrawn
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

        func moveTo(_ next: DefaultProgramEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default program estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default program estimate") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> DefaultProgramEstimate {
            return DefaultProgramEstimate(
                code: code,
                name: name,
                segment: segment,
                summary: summary,
                procedureCode: procedureCode,
                specialty: specialty,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a default program estimate in status proposed.
    static func newDefaultProgramEstimate(_ code: String, name: String) -> DefaultProgramEstimate {
        return DefaultProgramEstimate(
            code: code,
            name: name,
            segment: "",
            summary: "",
            procedureCode: "",
            specialty: "",
            quantity: 0,
            status: DefaultProgramEstimateStatus.proposed
        )
    }
}
