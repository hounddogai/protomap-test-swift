import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority quota is in its life cycle.
    enum PriorityQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One priority quota, with what the planners need to act on it.
    final class PriorityQuota {
        var code: String
        var label: String
        var acuity: Int
        var summary: String
        var batchSize: Int
        var priority: Int
        var allergy: String
        var description: String
        var visible: Bool
        var retries: Int
        var status: PriorityQuotaStatus

        init(code: String, label: String, acuity: Int, summary: String, batchSize: Int, priority: Int, allergy: String, description: String, visible: Bool, retries: Int, status: PriorityQuotaStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.summary = summary
            self.batchSize = batchSize
            self.priority = priority
            self.allergy = allergy
            self.description = description
            self.visible = visible
            self.retries = retries
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

        func canMoveTo(_ next: PriorityQuotaStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PriorityQuotaStatus.done || next == PriorityQuotaStatus.failed
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

        func moveTo(_ next: PriorityQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(acuity) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityQuota {
            return PriorityQuota(
                code: code,
                label: label,
                acuity: acuity,
                summary: summary,
                batchSize: batchSize,
                priority: priority,
                allergy: allergy,
                description: description,
                visible: visible,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a priority quota in status new.
    static func newPriorityQuota(_ code: String, label: String) -> PriorityQuota {
        return PriorityQuota(
            code: code,
            label: label,
            acuity: 0,
            summary: "",
            batchSize: 0,
            priority: 0,
            allergy: "",
            description: "",
            visible: false,
            retries: 0,
            status: PriorityQuotaStatus.new
        )
    }
}
