import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual proxy metric is in its life cycle.
    enum ManualProxyMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual proxy metric as the proxy team keeps it.
    final class ManualProxyMetric {
        var code: String
        var name: String
        var revision: Int
        var approved: Bool
        var ownerID: String
        var facility: String
        var createdAt: Int
        var label: String
        var bed: String
        var ward: String
        var acuity: Int
        var status: ManualProxyMetricStatus

        init(code: String, name: String, revision: Int, approved: Bool, ownerID: String, facility: String, createdAt: Int, label: String, bed: String, ward: String, acuity: Int, status: ManualProxyMetricStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.approved = approved
            self.ownerID = ownerID
            self.facility = facility
            self.createdAt = createdAt
            self.label = label
            self.bed = bed
            self.ward = ward
            self.acuity = acuity
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

        func canMoveTo(_ next: ManualProxyMetricStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ManualProxyMetricStatus.done || next == ManualProxyMetricStatus.failed
            case .done:
                return next == ManualProxyMetricStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualProxyMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual proxy metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("manual proxy metric") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(acuity) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualProxyMetric {
            return ManualProxyMetric(
                code: code,
                name: name,
                revision: revision,
                approved: approved,
                ownerID: ownerID,
                facility: facility,
                createdAt: createdAt,
                label: label,
                bed: bed,
                ward: ward,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a manual proxy metric in status new.
    static func newManualProxyMetric(_ code: String, name: String) -> ManualProxyMetric {
        return ManualProxyMetric(
            code: code,
            name: name,
            revision: 0,
            approved: false,
            ownerID: "",
            facility: "",
            createdAt: 0,
            label: "",
            bed: "",
            ward: "",
            acuity: 0,
            status: ManualProxyMetricStatus.new
        )
    }
}
