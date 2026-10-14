import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default recall entry is in its life cycle.
    enum DefaultRecallEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default recall entry as the recall team keeps it.
    final class DefaultRecallEntry {
        var code: String
        var name: String
        var approved: Bool
        var diagnosisCode: String
        var procedureCode: String
        var encounterID: String
        var title: String
        var score: Double
        var status: DefaultRecallEntryStatus

        init(code: String, name: String, approved: Bool, diagnosisCode: String, procedureCode: String, encounterID: String, title: String, score: Double, status: DefaultRecallEntryStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.procedureCode = procedureCode
            self.encounterID = encounterID
            self.title = title
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultRecallEntryStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultRecallEntryStatus.warming
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DefaultRecallEntryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRecallEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default recall entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default recall entry") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> DefaultRecallEntry {
            return DefaultRecallEntry(
                code: code,
                name: name,
                approved: approved,
                diagnosisCode: diagnosisCode,
                procedureCode: procedureCode,
                encounterID: encounterID,
                title: title,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default recall entry in status idle.
    static func newDefaultRecallEntry(_ code: String, name: String) -> DefaultRecallEntry {
        return DefaultRecallEntry(
            code: code,
            name: name,
            approved: false,
            diagnosisCode: "",
            procedureCode: "",
            encounterID: "",
            title: "",
            score: 0.0,
            status: DefaultRecallEntryStatus.idle
        )
    }
}
