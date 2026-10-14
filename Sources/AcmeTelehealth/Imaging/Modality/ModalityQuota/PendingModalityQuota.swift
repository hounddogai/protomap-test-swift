import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending modality quota is in its life cycle.
    enum PendingModalityQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending modality quota. Its code is unique within a tenant.
    final class PendingModalityQuota {
        var code: String
        var label: String
        var capacity: Int
        var weight: Double
        var dosageMg: Double
        var batchSize: Int
        var active: Bool
        var retries: Int
        var allergy: String
        var ratio: Double
        var timezone: String
        var status: PendingModalityQuotaStatus

        init(code: String, label: String, capacity: Int, weight: Double, dosageMg: Double, batchSize: Int, active: Bool, retries: Int, allergy: String, ratio: Double, timezone: String, status: PendingModalityQuotaStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.weight = weight
            self.dosageMg = dosageMg
            self.batchSize = batchSize
            self.active = active
            self.retries = retries
            self.allergy = allergy
            self.ratio = ratio
            self.timezone = timezone
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

        func canMoveTo(_ next: PendingModalityQuotaStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingModalityQuotaStatus.running
            case .queued:
                return next == PendingModalityQuotaStatus.running || next == PendingModalityQuotaStatus.failed
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: PendingModalityQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending modality quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending modality quota") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((weight - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PendingModalityQuota {
            return PendingModalityQuota(
                code: code,
                label: label,
                capacity: capacity,
                weight: weight,
                dosageMg: dosageMg,
                batchSize: batchSize,
                active: active,
                retries: retries,
                allergy: allergy,
                ratio: ratio,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending modality quota in status new.
    static func newPendingModalityQuota(_ code: String, label: String) -> PendingModalityQuota {
        return PendingModalityQuota(
            code: code,
            label: label,
            capacity: 0,
            weight: 0.0,
            dosageMg: 0.0,
            batchSize: 0,
            active: false,
            retries: 0,
            allergy: "",
            ratio: 0.0,
            timezone: "",
            status: PendingModalityQuotaStatus.new
        )
    }
}
