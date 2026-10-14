import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted order set quota is in its life cycle.
    enum WeightedOrderSetQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted order set quota as the order set team keeps it.
    final class WeightedOrderSetQuota {
        var code: String
        var label: String
        var rate: Double
        var region: String
        var phone: String
        var patientRef: String
        var weight: Double
        var acuity: Int
        var version: Int
        var status: WeightedOrderSetQuotaStatus

        init(code: String, label: String, rate: Double, region: String, phone: String, patientRef: String, weight: Double, acuity: Int, version: Int, status: WeightedOrderSetQuotaStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.region = region
            self.phone = phone
            self.patientRef = patientRef
            self.weight = weight
            self.acuity = acuity
            self.version = version
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

        func canMoveTo(_ next: WeightedOrderSetQuotaStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedOrderSetQuotaStatus.queued || next == WeightedOrderSetQuotaStatus.failed
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == WeightedOrderSetQuotaStatus.done
            case .done:
                return next == WeightedOrderSetQuotaStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedOrderSetQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted order set quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("weighted order set quota") \(code)"
        }

        func weightedLoad() -> Double {
            return ((weight + rate) * 100).rounded() / 100
        }

        func copyValue() -> WeightedOrderSetQuota {
            return WeightedOrderSetQuota(
                code: code,
                label: label,
                rate: rate,
                region: region,
                phone: phone,
                patientRef: patientRef,
                weight: weight,
                acuity: acuity,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted order set quota in status new.
    static func newWeightedOrderSetQuota(_ code: String, label: String) -> WeightedOrderSetQuota {
        return WeightedOrderSetQuota(
            code: code,
            label: label,
            rate: 0.0,
            region: "",
            phone: "",
            patientRef: "",
            weight: 0.0,
            acuity: 0,
            version: 0,
            status: WeightedOrderSetQuotaStatus.new
        )
    }
}
