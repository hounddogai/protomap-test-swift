import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal rollup is in its life cycle.
    enum GoalRollupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A goal rollup. Its code is unique within a tenant.
    final class GoalRollup {
        var code: String
        var title: String
        var checksum: String
        var tags: [String]
        var clinicianID: String
        var batchSize: Int
        var ownerID: String
        var retries: Int
        var dosageMg: Double
        var score: Double
        var status: GoalRollupStatus

        init(code: String, title: String, checksum: String, tags: [String], clinicianID: String, batchSize: Int, ownerID: String, retries: Int, dosageMg: Double, score: Double, status: GoalRollupStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.tags = tags
            self.clinicianID = clinicianID
            self.batchSize = batchSize
            self.ownerID = ownerID
            self.retries = retries
            self.dosageMg = dosageMg
            self.score = score
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

        func canMoveTo(_ next: GoalRollupStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: GoalRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return ((Double(batchSize) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> GoalRollup {
            return GoalRollup(
                code: code,
                title: title,
                checksum: checksum,
                tags: tags,
                clinicianID: clinicianID,
                batchSize: batchSize,
                ownerID: ownerID,
                retries: retries,
                dosageMg: dosageMg,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a goal rollup in status proposed.
    static func newGoalRollup(_ code: String, title: String) -> GoalRollup {
        return GoalRollup(
            code: code,
            title: title,
            checksum: "",
            tags: [],
            clinicianID: "",
            batchSize: 0,
            ownerID: "",
            retries: 0,
            dosageMg: 0.0,
            score: 0.0,
            status: GoalRollupStatus.proposed
        )
    }
}
