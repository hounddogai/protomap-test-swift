import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling worklist preference is in its life cycle.
    enum RollingWorklistPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling worklist preference as the worklist team keeps it.
    final class RollingWorklistPreference {
        var code: String
        var name: String
        var payer: String
        var tags: [String]
        var dosageMg: Double
        var limit: Int
        var reviewer: String
        var allergy: String
        var procedureCode: String
        var status: RollingWorklistPreferenceStatus

        init(code: String, name: String, payer: String, tags: [String], dosageMg: Double, limit: Int, reviewer: String, allergy: String, procedureCode: String, status: RollingWorklistPreferenceStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.tags = tags
            self.dosageMg = dosageMg
            self.limit = limit
            self.reviewer = reviewer
            self.allergy = allergy
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: RollingWorklistPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
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
                switch next {
                case .closed:
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

        func moveTo(_ next: RollingWorklistPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling worklist preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return (dosageMg * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> RollingWorklistPreference {
            return RollingWorklistPreference(
                code: code,
                name: name,
                payer: payer,
                tags: tags,
                dosageMg: dosageMg,
                limit: limit,
                reviewer: reviewer,
                allergy: allergy,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling worklist preference in status draft.
    static func newRollingWorklistPreference(_ code: String, name: String) -> RollingWorklistPreference {
        return RollingWorklistPreference(
            code: code,
            name: name,
            payer: "",
            tags: [],
            dosageMg: 0.0,
            limit: 0,
            reviewer: "",
            allergy: "",
            procedureCode: "",
            status: RollingWorklistPreferenceStatus.draft
        )
    }
}
