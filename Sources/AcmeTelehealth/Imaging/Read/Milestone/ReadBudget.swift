import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read budget is in its life cycle.
    enum ReadBudgetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a read budget and its current status.
    final class ReadBudget {
        var code: String
        var title: String
        var refills: Int
        var clinicianID: String
        var visitMinutes: Int
        var retries: Int
        var category: String
        var revision: Int
        var status: ReadBudgetStatus

        init(code: String, title: String, refills: Int, clinicianID: String, visitMinutes: Int, retries: Int, category: String, revision: Int, status: ReadBudgetStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.clinicianID = clinicianID
            self.visitMinutes = visitMinutes
            self.retries = retries
            self.category = category
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReadBudgetStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ReadBudgetStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ReadBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netVolume() -> Double {
            return ((Double(retries) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ReadBudget {
            return ReadBudget(
                code: code,
                title: title,
                refills: refills,
                clinicianID: clinicianID,
                visitMinutes: visitMinutes,
                retries: retries,
                category: category,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a read budget in status created.
    static func newReadBudget(_ code: String, title: String) -> ReadBudget {
        return ReadBudget(
            code: code,
            title: title,
            refills: 0,
            clinicianID: "",
            visitMinutes: 0,
            retries: 0,
            category: "",
            revision: 0,
            status: ReadBudgetStatus.created
        )
    }
}
