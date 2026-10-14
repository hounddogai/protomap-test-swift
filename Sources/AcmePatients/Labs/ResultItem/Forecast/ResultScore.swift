import AcmePlatform
import Foundation

extension Labs {
    /// Where a result score is in its life cycle.
    enum ResultScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A result score as the result team keeps it.
    final class ResultScore {
        var code: String
        var name: String
        var phone: String
        var patientRef: String
        var revision: Int
        var status: ResultScoreStatus

        init(code: String, name: String, phone: String, patientRef: String, revision: Int, status: ResultScoreStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.patientRef = patientRef
            self.revision = revision
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

        func canMoveTo(_ next: ResultScoreStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ResultScoreStatus.reopened
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

        func moveTo(_ next: ResultScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> ResultScore {
            return ResultScore(
                code: code,
                name: name,
                phone: phone,
                patientRef: patientRef,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a result score in status open.
    static func newResultScore(_ code: String, name: String) -> ResultScore {
        return ResultScore(
            code: code,
            name: name,
            phone: "",
            patientRef: "",
            revision: 0,
            status: ResultScoreStatus.`open`
        )
    }
}
