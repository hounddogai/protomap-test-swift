import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped result rule is in its life cycle.
    enum CappedResultRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A capped result rule. Its code is unique within a tenant.
    final class CappedResultRule {
        var code: String
        var name: String
        var startsAt: Int
        var source: String
        var approved: Bool
        var version: Int
        var revision: Int
        var windowDays: Int
        var category: String
        var patientRef: String
        var threshold: Double
        var status: CappedResultRuleStatus

        init(code: String, name: String, startsAt: Int, source: String, approved: Bool, version: Int, revision: Int, windowDays: Int, category: String, patientRef: String, threshold: Double, status: CappedResultRuleStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.source = source
            self.approved = approved
            self.version = version
            self.revision = revision
            self.windowDays = windowDays
            self.category = category
            self.patientRef = patientRef
            self.threshold = threshold
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

        func canMoveTo(_ next: CappedResultRuleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CappedResultRuleStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CappedResultRuleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedResultRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped result rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return ((Double(version) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> CappedResultRule {
            return CappedResultRule(
                code: code,
                name: name,
                startsAt: startsAt,
                source: source,
                approved: approved,
                version: version,
                revision: revision,
                windowDays: windowDays,
                category: category,
                patientRef: patientRef,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a capped result rule in status draft.
    static func newCappedResultRule(_ code: String, name: String) -> CappedResultRule {
        return CappedResultRule(
            code: code,
            name: name,
            startsAt: 0,
            source: "",
            approved: false,
            version: 0,
            revision: 0,
            windowDays: 0,
            category: "",
            patientRef: "",
            threshold: 0.0,
            status: CappedResultRuleStatus.draft
        )
    }
}
