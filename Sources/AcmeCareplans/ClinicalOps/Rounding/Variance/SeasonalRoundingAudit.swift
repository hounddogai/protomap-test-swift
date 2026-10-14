import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal rounding audit is in its life cycle.
    enum SeasonalRoundingAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One seasonal rounding audit, with what the planners need to act on it.
    final class SeasonalRoundingAudit {
        var code: String
        var name: String
        var tags: [String]
        var encounterID: String
        var version: Int
        var batchSize: Int
        var specialty: String
        var status: SeasonalRoundingAuditStatus

        init(code: String, name: String, tags: [String], encounterID: String, version: Int, batchSize: Int, specialty: String, status: SeasonalRoundingAuditStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.encounterID = encounterID
            self.version = version
            self.batchSize = batchSize
            self.specialty = specialty
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

        func canMoveTo(_ next: SeasonalRoundingAuditStatus) -> Bool {
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
                return next == SeasonalRoundingAuditStatus.active || next == SeasonalRoundingAuditStatus.suspended
            case .active:
                return next == SeasonalRoundingAuditStatus.suspended || next == SeasonalRoundingAuditStatus.closed
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

        func moveTo(_ next: SeasonalRoundingAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal rounding audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("seasonal rounding audit") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedExposure() -> Double {
            return ((Double(version) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalRoundingAudit {
            return SeasonalRoundingAudit(
                code: code,
                name: name,
                tags: tags,
                encounterID: encounterID,
                version: version,
                batchSize: batchSize,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal rounding audit in status draft.
    static func newSeasonalRoundingAudit(_ code: String, name: String) -> SeasonalRoundingAudit {
        return SeasonalRoundingAudit(
            code: code,
            name: name,
            tags: [],
            encounterID: "",
            version: 0,
            batchSize: 0,
            specialty: "",
            status: SeasonalRoundingAuditStatus.draft
        )
    }
}
