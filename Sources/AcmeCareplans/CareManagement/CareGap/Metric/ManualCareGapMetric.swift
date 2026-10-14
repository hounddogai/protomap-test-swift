import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual care gap metric is in its life cycle.
    enum ManualCareGapMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A manual care gap metric. Its code is unique within a tenant.
    final class ManualCareGapMetric {
        var code: String
        var name: String
        var revision: Int
        var specialty: String
        var region: String
        var visible: Bool
        var label: String
        var batchSize: Int
        var status: ManualCareGapMetricStatus

        init(code: String, name: String, revision: Int, specialty: String, region: String, visible: Bool, label: String, batchSize: Int, status: ManualCareGapMetricStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.specialty = specialty
            self.region = region
            self.visible = visible
            self.label = label
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualCareGapMetricStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ManualCareGapMetricStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ManualCareGapMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care gap metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("manual care gap metric") \(code)"
        }

        func netValue() -> Double {
            return ((Double(batchSize) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ManualCareGapMetric {
            return ManualCareGapMetric(
                code: code,
                name: name,
                revision: revision,
                specialty: specialty,
                region: region,
                visible: visible,
                label: label,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual care gap metric in status idle.
    static func newManualCareGapMetric(_ code: String, name: String) -> ManualCareGapMetric {
        return ManualCareGapMetric(
            code: code,
            name: name,
            revision: 0,
            specialty: "",
            region: "",
            visible: false,
            label: "",
            batchSize: 0,
            status: ManualCareGapMetricStatus.idle
        )
    }
}
