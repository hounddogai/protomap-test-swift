import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled handoff quota is in its life cycle.
    enum ScheduledHandoffQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled handoff quota. Its code is unique within a tenant.
    final class ScheduledHandoffQuota {
        var code: String
        var name: String
        var patientRef: String
        var cost: Double
        var retries: Int
        var label: String
        var floorValue: Double
        var bed: String
        var budget: Double
        var status: ScheduledHandoffQuotaStatus

        init(code: String, name: String, patientRef: String, cost: Double, retries: Int, label: String, floorValue: Double, bed: String, budget: Double, status: ScheduledHandoffQuotaStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.cost = cost
            self.retries = retries
            self.label = label
            self.floorValue = floorValue
            self.bed = bed
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

        func canMoveTo(_ next: ScheduledHandoffQuotaStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ScheduledHandoffQuotaStatus.running || next == ScheduledHandoffQuotaStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ScheduledHandoffQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled handoff quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func netTotal() -> Double {
            return ((floorValue - cost) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledHandoffQuota {
            return ScheduledHandoffQuota(
                code: code,
                name: name,
                patientRef: patientRef,
                cost: cost,
                retries: retries,
                label: label,
                floorValue: floorValue,
                bed: bed,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled handoff quota in status new.
    static func newScheduledHandoffQuota(_ code: String, name: String) -> ScheduledHandoffQuota {
        return ScheduledHandoffQuota(
            code: code,
            name: name,
            patientRef: "",
            cost: 0.0,
            retries: 0,
            label: "",
            floorValue: 0.0,
            bed: "",
            budget: 0.0,
            status: ScheduledHandoffQuotaStatus.new
        )
    }
}
