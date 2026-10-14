import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped accession metric is in its life cycle.
    enum CappedAccessionMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a capped accession metric and its current status.
    final class CappedAccessionMetric {
        var code: String
        var title: String
        var score: Double
        var threshold: Double
        var ceiling: Double
        var ward: String
        var cost: Double
        var attempts: Int
        var sequence: Int
        var version: Int
        var status: CappedAccessionMetricStatus

        init(code: String, title: String, score: Double, threshold: Double, ceiling: Double, ward: String, cost: Double, attempts: Int, sequence: Int, version: Int, status: CappedAccessionMetricStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.threshold = threshold
            self.ceiling = ceiling
            self.ward = ward
            self.cost = cost
            self.attempts = attempts
            self.sequence = sequence
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

        func canMoveTo(_ next: CappedAccessionMetricStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CappedAccessionMetricStatus.done || next == CappedAccessionMetricStatus.failed
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

        func moveTo(_ next: CappedAccessionMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped accession metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedValue() -> Double {
            return ((ceiling - threshold) * 100).rounded() / 100
        }

        func copyValue() -> CappedAccessionMetric {
            return CappedAccessionMetric(
                code: code,
                title: title,
                score: score,
                threshold: threshold,
                ceiling: ceiling,
                ward: ward,
                cost: cost,
                attempts: attempts,
                sequence: sequence,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped accession metric in status new.
    static func newCappedAccessionMetric(_ code: String, title: String) -> CappedAccessionMetric {
        return CappedAccessionMetric(
            code: code,
            title: title,
            score: 0.0,
            threshold: 0.0,
            ceiling: 0.0,
            ward: "",
            cost: 0.0,
            attempts: 0,
            sequence: 0,
            version: 0,
            status: CappedAccessionMetricStatus.new
        )
    }
}
