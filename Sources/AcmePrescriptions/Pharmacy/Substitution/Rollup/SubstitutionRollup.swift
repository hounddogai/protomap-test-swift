import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution rollup is in its life cycle.
    enum SubstitutionRollupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a substitution rollup and its current status.
    final class SubstitutionRollup {
        var code: String
        var name: String
        var procedureCode: String
        var updatedAt: Int
        var createdAt: Int
        var archived: Bool
        var margin: Double
        var unit: String
        var bed: String
        var status: SubstitutionRollupStatus

        init(code: String, name: String, procedureCode: String, updatedAt: Int, createdAt: Int, archived: Bool, margin: Double, unit: String, bed: String, status: SubstitutionRollupStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.archived = archived
            self.margin = margin
            self.unit = unit
            self.bed = bed
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

        func canMoveTo(_ next: SubstitutionRollupStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: SubstitutionRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedVolume() -> Double {
            return ((Double(createdAt) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionRollup {
            return SubstitutionRollup(
                code: code,
                name: name,
                procedureCode: procedureCode,
                updatedAt: updatedAt,
                createdAt: createdAt,
                archived: archived,
                margin: margin,
                unit: unit,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a substitution rollup in status proposed.
    static func newSubstitutionRollup(_ code: String, name: String) -> SubstitutionRollup {
        return SubstitutionRollup(
            code: code,
            name: name,
            procedureCode: "",
            updatedAt: 0,
            createdAt: 0,
            archived: false,
            margin: 0.0,
            unit: "",
            bed: "",
            status: SubstitutionRollupStatus.proposed
        )
    }
}
