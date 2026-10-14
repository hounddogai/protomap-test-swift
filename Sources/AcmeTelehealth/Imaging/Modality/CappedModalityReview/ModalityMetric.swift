import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality metric is in its life cycle.
    enum ModalityMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One modality metric, with what the planners need to act on it.
    final class ModalityMetric {
        var code: String
        var label: String
        var summary: String
        var maximum: Double
        var endsAt: Int
        var bed: String
        var status: ModalityMetricStatus

        init(code: String, label: String, summary: String, maximum: Double, endsAt: Int, bed: String, status: ModalityMetricStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.maximum = maximum
            self.endsAt = endsAt
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityMetricStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ModalityMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("modality metric") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(endsAt) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> ModalityMetric {
            return ModalityMetric(
                code: code,
                label: label,
                summary: summary,
                maximum: maximum,
                endsAt: endsAt,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a modality metric in status requested.
    static func newModalityMetric(_ code: String, label: String) -> ModalityMetric {
        return ModalityMetric(
            code: code,
            label: label,
            summary: "",
            maximum: 0.0,
            endsAt: 0,
            bed: "",
            status: ModalityMetricStatus.requested
        )
    }
}
