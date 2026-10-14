import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual priority rule is in its life cycle.
    enum ManualPriorityRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual priority rule. Its code is unique within a tenant.
    final class ManualPriorityRule {
        var code: String
        var title: String
        var priority: Int
        var active: Bool
        var segment: String
        var visitMinutes: Int
        var batchSize: Int
        var region: String
        var status: ManualPriorityRuleStatus

        init(code: String, title: String, priority: Int, active: Bool, segment: String, visitMinutes: Int, batchSize: Int, region: String, status: ManualPriorityRuleStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.active = active
            self.segment = segment
            self.visitMinutes = visitMinutes
            self.batchSize = batchSize
            self.region = region
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

        func canMoveTo(_ next: ManualPriorityRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ManualPriorityRuleStatus.running || next == ManualPriorityRuleStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ManualPriorityRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualPriorityRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual priority rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual priority rule") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(priority) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ManualPriorityRule {
            return ManualPriorityRule(
                code: code,
                title: title,
                priority: priority,
                active: active,
                segment: segment,
                visitMinutes: visitMinutes,
                batchSize: batchSize,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual priority rule in status new.
    static func newManualPriorityRule(_ code: String, title: String) -> ManualPriorityRule {
        return ManualPriorityRule(
            code: code,
            title: title,
            priority: 0,
            active: false,
            segment: "",
            visitMinutes: 0,
            batchSize: 0,
            region: "",
            status: ManualPriorityRuleStatus.new
        )
    }
}
