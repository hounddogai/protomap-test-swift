import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program estimate is in its life cycle.
    enum ProgramEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One program estimate, with what the planners need to act on it.
    final class ProgramEstimate {
        var code: String
        var title: String
        var retries: Int
        var cost: Double
        var segment: String
        var approved: Bool
        var status: ProgramEstimateStatus

        init(code: String, title: String, retries: Int, cost: Double, segment: String, approved: Bool, status: ProgramEstimateStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.cost = cost
            self.segment = segment
            self.approved = approved
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

        func canMoveTo(_ next: ProgramEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ProgramEstimateStatus.withdrawn
            case .rejected:
                return next == ProgramEstimateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("program estimate") \(code)"
        }

        func weightedValue() -> Double {
            return ((cost - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramEstimate {
            return ProgramEstimate(
                code: code,
                title: title,
                retries: retries,
                cost: cost,
                segment: segment,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a program estimate in status proposed.
    static func newProgramEstimate(_ code: String, title: String) -> ProgramEstimate {
        return ProgramEstimate(
            code: code,
            title: title,
            retries: 0,
            cost: 0.0,
            segment: "",
            approved: false,
            status: ProgramEstimateStatus.proposed
        )
    }
}
