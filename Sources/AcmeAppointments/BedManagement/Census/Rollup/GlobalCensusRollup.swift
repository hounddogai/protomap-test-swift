import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global census rollup is in its life cycle.
    enum GlobalCensusRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One global census rollup, with what the planners need to act on it.
    final class GlobalCensusRollup {
        var code: String
        var name: String
        var summary: String
        var checksum: String
        var ownerID: String
        var approved: Bool
        var externalRef: String
        var createdAt: Int
        var margin: Double
        var dosageMg: Double
        var floorValue: Double
        var status: GlobalCensusRollupStatus

        init(code: String, name: String, summary: String, checksum: String, ownerID: String, approved: Bool, externalRef: String, createdAt: Int, margin: Double, dosageMg: Double, floorValue: Double, status: GlobalCensusRollupStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.checksum = checksum
            self.ownerID = ownerID
            self.approved = approved
            self.externalRef = externalRef
            self.createdAt = createdAt
            self.margin = margin
            self.dosageMg = dosageMg
            self.floorValue = floorValue
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

        func canMoveTo(_ next: GlobalCensusRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == GlobalCensusRollupStatus.active || next == GlobalCensusRollupStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == GlobalCensusRollupStatus.suspended || next == GlobalCensusRollupStatus.closed
            case .suspended:
                return next == GlobalCensusRollupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCensusRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global census rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveExposure() -> Double {
            return ((floorValue + margin) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCensusRollup {
            return GlobalCensusRollup(
                code: code,
                name: name,
                summary: summary,
                checksum: checksum,
                ownerID: ownerID,
                approved: approved,
                externalRef: externalRef,
                createdAt: createdAt,
                margin: margin,
                dosageMg: dosageMg,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global census rollup in status draft.
    static func newGlobalCensusRollup(_ code: String, name: String) -> GlobalCensusRollup {
        return GlobalCensusRollup(
            code: code,
            name: name,
            summary: "",
            checksum: "",
            ownerID: "",
            approved: false,
            externalRef: "",
            createdAt: 0,
            margin: 0.0,
            dosageMg: 0.0,
            floorValue: 0.0,
            status: GlobalCensusRollupStatus.draft
        )
    }
}
