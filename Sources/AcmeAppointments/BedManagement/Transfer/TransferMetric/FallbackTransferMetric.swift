import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback transfer metric is in its life cycle.
    enum FallbackTransferMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback transfer metric as the transfer team keeps it.
    final class FallbackTransferMetric {
        var code: String
        var label: String
        var name: String
        var ward: String
        var acuity: Int
        var windowDays: Int
        var visitMinutes: Int
        var copay: Double
        var unit: String
        var status: FallbackTransferMetricStatus

        init(code: String, label: String, name: String, ward: String, acuity: Int, windowDays: Int, visitMinutes: Int, copay: Double, unit: String, status: FallbackTransferMetricStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.ward = ward
            self.acuity = acuity
            self.windowDays = windowDays
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackTransferMetricStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == FallbackTransferMetricStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackTransferMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback transfer metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return ((Double(windowDays) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackTransferMetric {
            return FallbackTransferMetric(
                code: code,
                label: label,
                name: name,
                ward: ward,
                acuity: acuity,
                windowDays: windowDays,
                visitMinutes: visitMinutes,
                copay: copay,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback transfer metric in status proposed.
    static func newFallbackTransferMetric(_ code: String, label: String) -> FallbackTransferMetric {
        return FallbackTransferMetric(
            code: code,
            label: label,
            name: "",
            ward: "",
            acuity: 0,
            windowDays: 0,
            visitMinutes: 0,
            copay: 0.0,
            unit: "",
            status: FallbackTransferMetricStatus.proposed
        )
    }
}
