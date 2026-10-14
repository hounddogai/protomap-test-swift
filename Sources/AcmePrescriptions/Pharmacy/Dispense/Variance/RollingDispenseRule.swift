import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling dispense rule is in its life cycle.
    enum RollingDispenseRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One rolling dispense rule, with what the planners need to act on it.
    final class RollingDispenseRule {
        var code: String
        var label: String
        var archived: Bool
        var cost: Double
        var patientRef: String
        var endsAt: Int
        var pinned: Bool
        var bed: String
        var retries: Int
        var tags: [String]
        var status: RollingDispenseRuleStatus

        init(code: String, label: String, archived: Bool, cost: Double, patientRef: String, endsAt: Int, pinned: Bool, bed: String, retries: Int, tags: [String], status: RollingDispenseRuleStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.cost = cost
            self.patientRef = patientRef
            self.endsAt = endsAt
            self.pinned = pinned
            self.bed = bed
            self.retries = retries
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingDispenseRuleStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingDispenseRuleStatus.running
            case .queued:
                return next == RollingDispenseRuleStatus.failed
            case .running:
                return next == RollingDispenseRuleStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RollingDispenseRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling dispense rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return (cost * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> RollingDispenseRule {
            return RollingDispenseRule(
                code: code,
                label: label,
                archived: archived,
                cost: cost,
                patientRef: patientRef,
                endsAt: endsAt,
                pinned: pinned,
                bed: bed,
                retries: retries,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling dispense rule in status new.
    static func newRollingDispenseRule(_ code: String, label: String) -> RollingDispenseRule {
        return RollingDispenseRule(
            code: code,
            label: label,
            archived: false,
            cost: 0.0,
            patientRef: "",
            endsAt: 0,
            pinned: false,
            bed: "",
            retries: 0,
            tags: [],
            status: RollingDispenseRuleStatus.new
        )
    }
}
