import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program budget is in its life cycle.
    enum ProgramBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One program budget, with what the planners need to act on it.
    final class ProgramBudget {
        var code: String
        var title: String
        var category: String
        var batchSize: Int
        var ward: String
        var specialty: String
        var version: Int
        var externalRef: String
        var startsAt: Int
        var ownerID: String
        var notes: String
        var status: ProgramBudgetStatus

        init(code: String, title: String, category: String, batchSize: Int, ward: String, specialty: String, version: Int, externalRef: String, startsAt: Int, ownerID: String, notes: String, status: ProgramBudgetStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.batchSize = batchSize
            self.ward = ward
            self.specialty = specialty
            self.version = version
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.ownerID = ownerID
            self.notes = notes
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

        func canMoveTo(_ next: ProgramBudgetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
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
                return next == ProgramBudgetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveLoad() -> Double {
            return ((Double(batchSize) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramBudget {
            return ProgramBudget(
                code: code,
                title: title,
                category: category,
                batchSize: batchSize,
                ward: ward,
                specialty: specialty,
                version: version,
                externalRef: externalRef,
                startsAt: startsAt,
                ownerID: ownerID,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a program budget in status draft.
    static func newProgramBudget(_ code: String, title: String) -> ProgramBudget {
        return ProgramBudget(
            code: code,
            title: title,
            category: "",
            batchSize: 0,
            ward: "",
            specialty: "",
            version: 0,
            externalRef: "",
            startsAt: 0,
            ownerID: "",
            notes: "",
            status: ProgramBudgetStatus.draft
        )
    }
}
