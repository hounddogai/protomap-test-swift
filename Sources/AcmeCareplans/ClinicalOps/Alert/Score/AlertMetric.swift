import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert metric is in its life cycle.
    enum AlertMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a alert metric and its current status.
    final class AlertMetric {
        var code: String
        var label: String
        var currency: String
        var allergy: String
        var checksum: String
        var copay: Double
        var segment: String
        var createdAt: Int
        var score: Double
        var status: AlertMetricStatus

        init(code: String, label: String, currency: String, allergy: String, checksum: String, copay: Double, segment: String, createdAt: Int, score: Double, status: AlertMetricStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.allergy = allergy
            self.checksum = checksum
            self.copay = copay
            self.segment = segment
            self.createdAt = createdAt
            self.score = score
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

        func canMoveTo(_ next: AlertMetricStatus) -> Bool {
            switch status {
            case .requested:
                return next == AlertMetricStatus.granted || next == AlertMetricStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AlertMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedLoad() -> Double {
            return ((copay - score) * 100).rounded() / 100
        }

        func copyValue() -> AlertMetric {
            return AlertMetric(
                code: code,
                label: label,
                currency: currency,
                allergy: allergy,
                checksum: checksum,
                copay: copay,
                segment: segment,
                createdAt: createdAt,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a alert metric in status requested.
    static func newAlertMetric(_ code: String, label: String) -> AlertMetric {
        return AlertMetric(
            code: code,
            label: label,
            currency: "",
            allergy: "",
            checksum: "",
            copay: 0.0,
            segment: "",
            createdAt: 0,
            score: 0.0,
            status: AlertMetricStatus.requested
        )
    }
}
