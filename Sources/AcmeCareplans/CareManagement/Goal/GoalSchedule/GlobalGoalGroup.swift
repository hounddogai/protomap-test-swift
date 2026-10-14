import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global goal group is in its life cycle.
    enum GlobalGoalGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One global goal group, with what the planners need to act on it.
    final class GlobalGoalGroup {
        var code: String
        var title: String
        var source: String
        var phone: String
        var notes: String
        var rate: Double
        var diagnosisCode: String
        var payer: String
        var status: GlobalGoalGroupStatus

        init(code: String, title: String, source: String, phone: String, notes: String, rate: Double, diagnosisCode: String, payer: String, status: GlobalGoalGroupStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.phone = phone
            self.notes = notes
            self.rate = rate
            self.diagnosisCode = diagnosisCode
            self.payer = payer
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

        func canMoveTo(_ next: GlobalGoalGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == GlobalGoalGroupStatus.pending || next == GlobalGoalGroupStatus.active
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == GlobalGoalGroupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalGoalGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global goal group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> GlobalGoalGroup {
            return GlobalGoalGroup(
                code: code,
                title: title,
                source: source,
                phone: phone,
                notes: notes,
                rate: rate,
                diagnosisCode: diagnosisCode,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a global goal group in status draft.
    static func newGlobalGoalGroup(_ code: String, title: String) -> GlobalGoalGroup {
        return GlobalGoalGroup(
            code: code,
            title: title,
            source: "",
            phone: "",
            notes: "",
            rate: 0.0,
            diagnosisCode: "",
            payer: "",
            status: GlobalGoalGroupStatus.draft
        )
    }
}
