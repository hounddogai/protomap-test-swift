import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped statement snapshot is in its life cycle.
    enum CappedStatementSnapshotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a capped statement snapshot and its current status.
    final class CappedStatementSnapshot {
        var code: String
        var title: String
        var country: String
        var version: Int
        var patientRef: String
        var timezone: String
        var status: CappedStatementSnapshotStatus

        init(code: String, title: String, country: String, version: Int, patientRef: String, timezone: String, status: CappedStatementSnapshotStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.version = version
            self.patientRef = patientRef
            self.timezone = timezone
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

        func canMoveTo(_ next: CappedStatementSnapshotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
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
                return next == CappedStatementSnapshotStatus.archived
            case .reopened:
                return next == CappedStatementSnapshotStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedStatementSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped statement snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> CappedStatementSnapshot {
            return CappedStatementSnapshot(
                code: code,
                title: title,
                country: country,
                version: version,
                patientRef: patientRef,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a capped statement snapshot in status open.
    static func newCappedStatementSnapshot(_ code: String, title: String) -> CappedStatementSnapshot {
        return CappedStatementSnapshot(
            code: code,
            title: title,
            country: "",
            version: 0,
            patientRef: "",
            timezone: "",
            status: CappedStatementSnapshotStatus.`open`
        )
    }
}
