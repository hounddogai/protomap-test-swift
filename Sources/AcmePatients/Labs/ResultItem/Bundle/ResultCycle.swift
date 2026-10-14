import AcmePlatform
import Foundation

extension Labs {
    /// Where a result cycle is in its life cycle.
    enum ResultCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One result cycle, with what the planners need to act on it.
    final class ResultCycle {
        var code: String
        var name: String
        var discount: Double
        var batchSize: Int
        var specialty: String
        var approved: Bool
        var procedureCode: String
        var visitMinutes: Int
        var visible: Bool
        var channel: String
        var status: ResultCycleStatus

        init(code: String, name: String, discount: Double, batchSize: Int, specialty: String, approved: Bool, procedureCode: String, visitMinutes: Int, visible: Bool, channel: String, status: ResultCycleStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.batchSize = batchSize
            self.specialty = specialty
            self.approved = approved
            self.procedureCode = procedureCode
            self.visitMinutes = visitMinutes
            self.visible = visible
            self.channel = channel
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

        func canMoveTo(_ next: ResultCycleStatus) -> Bool {
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
                return next == ResultCycleStatus.revoked || next == ResultCycleStatus.expired
            case .revoked:
                return next == ResultCycleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("result cycle") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((discount + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ResultCycle {
            return ResultCycle(
                code: code,
                name: name,
                discount: discount,
                batchSize: batchSize,
                specialty: specialty,
                approved: approved,
                procedureCode: procedureCode,
                visitMinutes: visitMinutes,
                visible: visible,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a result cycle in status requested.
    static func newResultCycle(_ code: String, name: String) -> ResultCycle {
        return ResultCycle(
            code: code,
            name: name,
            discount: 0.0,
            batchSize: 0,
            specialty: "",
            approved: false,
            procedureCode: "",
            visitMinutes: 0,
            visible: false,
            channel: "",
            status: ResultCycleStatus.requested
        )
    }
}
