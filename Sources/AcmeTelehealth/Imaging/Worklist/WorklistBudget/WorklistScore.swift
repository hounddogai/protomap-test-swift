import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist score is in its life cycle.
    enum WorklistScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a worklist score and its current status.
    final class WorklistScore {
        var code: String
        var title: String
        var currency: String
        var visitMinutes: Int
        var sequence: Int
        var bed: String
        var patientRef: String
        var channel: String
        var specialty: String
        var status: WorklistScoreStatus

        init(code: String, title: String, currency: String, visitMinutes: Int, sequence: Int, bed: String, patientRef: String, channel: String, specialty: String, status: WorklistScoreStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.sequence = sequence
            self.bed = bed
            self.patientRef = patientRef
            self.channel = channel
            self.specialty = specialty
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

        func canMoveTo(_ next: WorklistScoreStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WorklistScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((Double(sequence) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistScore {
            return WorklistScore(
                code: code,
                title: title,
                currency: currency,
                visitMinutes: visitMinutes,
                sequence: sequence,
                bed: bed,
                patientRef: patientRef,
                channel: channel,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a worklist score in status proposed.
    static func newWorklistScore(_ code: String, title: String) -> WorklistScore {
        return WorklistScore(
            code: code,
            title: title,
            currency: "",
            visitMinutes: 0,
            sequence: 0,
            bed: "",
            patientRef: "",
            channel: "",
            specialty: "",
            status: WorklistScoreStatus.proposed
        )
    }
}
