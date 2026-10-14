import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional network rule is in its life cycle.
    enum RegionalNetworkRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A regional network rule. Its code is unique within a tenant.
    final class RegionalNetworkRule {
        var code: String
        var title: String
        var batchSize: Int
        var amount: Double
        var priority: Int
        var summary: String
        var patientRef: String
        var version: Int
        var procedureCode: String
        var checksum: String
        var budget: Double
        var status: RegionalNetworkRuleStatus

        init(code: String, title: String, batchSize: Int, amount: Double, priority: Int, summary: String, patientRef: String, version: Int, procedureCode: String, checksum: String, budget: Double, status: RegionalNetworkRuleStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.amount = amount
            self.priority = priority
            self.summary = summary
            self.patientRef = patientRef
            self.version = version
            self.procedureCode = procedureCode
            self.checksum = checksum
            self.budget = budget
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

        func canMoveTo(_ next: RegionalNetworkRuleStatus) -> Bool {
            switch status {
            case .new:
                return next == RegionalNetworkRuleStatus.running
            case .queued:
                return next == RegionalNetworkRuleStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RegionalNetworkRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalNetworkRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional network rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedVolume() -> Double {
            return ((Double(version) - amount) * 100).rounded() / 100
        }

        func copyValue() -> RegionalNetworkRule {
            return RegionalNetworkRule(
                code: code,
                title: title,
                batchSize: batchSize,
                amount: amount,
                priority: priority,
                summary: summary,
                patientRef: patientRef,
                version: version,
                procedureCode: procedureCode,
                checksum: checksum,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional network rule in status new.
    static func newRegionalNetworkRule(_ code: String, title: String) -> RegionalNetworkRule {
        return RegionalNetworkRule(
            code: code,
            title: title,
            batchSize: 0,
            amount: 0.0,
            priority: 0,
            summary: "",
            patientRef: "",
            version: 0,
            procedureCode: "",
            checksum: "",
            budget: 0.0,
            status: RegionalNetworkRuleStatus.new
        )
    }
}
