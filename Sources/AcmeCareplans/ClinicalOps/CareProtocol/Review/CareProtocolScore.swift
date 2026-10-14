import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol score is in its life cycle.
    enum CareProtocolScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One care protocol score, with what the planners need to act on it.
    final class CareProtocolScore {
        var code: String
        var title: String
        var description: String
        var procedureCode: String
        var specialty: String
        var facility: String
        var channel: String
        var budget: Double
        var status: CareProtocolScoreStatus

        init(code: String, title: String, description: String, procedureCode: String, specialty: String, facility: String, channel: String, budget: Double, status: CareProtocolScoreStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.facility = facility
            self.channel = channel
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolScoreStatus) -> Bool {
            switch status {
            case .new:
                return next == CareProtocolScoreStatus.queued || next == CareProtocolScoreStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CareProtocolScoreStatus.failed
            case .done:
                return next == CareProtocolScoreStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> CareProtocolScore {
            return CareProtocolScore(
                code: code,
                title: title,
                description: description,
                procedureCode: procedureCode,
                specialty: specialty,
                facility: facility,
                channel: channel,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a care protocol score in status new.
    static func newCareProtocolScore(_ code: String, title: String) -> CareProtocolScore {
        return CareProtocolScore(
            code: code,
            title: title,
            description: "",
            procedureCode: "",
            specialty: "",
            facility: "",
            channel: "",
            budget: 0.0,
            status: CareProtocolScoreStatus.new
        )
    }
}
