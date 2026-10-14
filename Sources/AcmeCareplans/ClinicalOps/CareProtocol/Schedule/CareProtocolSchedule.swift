import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol schedule is in its life cycle.
    enum CareProtocolScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One care protocol schedule, with what the planners need to act on it.
    final class CareProtocolSchedule {
        var code: String
        var title: String
        var batchSize: Int
        var channel: String
        var approved: Bool
        var attempts: Int
        var budget: Double
        var copay: Double
        var externalRef: String
        var ratio: Double
        var procedureCode: String
        var status: CareProtocolScheduleStatus

        init(code: String, title: String, batchSize: Int, channel: String, approved: Bool, attempts: Int, budget: Double, copay: Double, externalRef: String, ratio: Double, procedureCode: String, status: CareProtocolScheduleStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.channel = channel
            self.approved = approved
            self.attempts = attempts
            self.budget = budget
            self.copay = copay
            self.externalRef = externalRef
            self.ratio = ratio
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: CareProtocolScheduleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CareProtocolScheduleStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CareProtocolScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol schedule") \(code)"
        }

        func netTotal() -> Double {
            return ((copay - budget) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolSchedule {
            return CareProtocolSchedule(
                code: code,
                title: title,
                batchSize: batchSize,
                channel: channel,
                approved: approved,
                attempts: attempts,
                budget: budget,
                copay: copay,
                externalRef: externalRef,
                ratio: ratio,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a care protocol schedule in status planned.
    static func newCareProtocolSchedule(_ code: String, title: String) -> CareProtocolSchedule {
        return CareProtocolSchedule(
            code: code,
            title: title,
            batchSize: 0,
            channel: "",
            approved: false,
            attempts: 0,
            budget: 0.0,
            copay: 0.0,
            externalRef: "",
            ratio: 0.0,
            procedureCode: "",
            status: CareProtocolScheduleStatus.planned
        )
    }
}
