import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score variance is in its life cycle.
    enum RiskScoreVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One risk score variance, with what the planners need to act on it.
    final class RiskScoreVariance {
        var code: String
        var name: String
        var threshold: Double
        var segment: String
        var externalRef: String
        var currency: String
        var priority: Int
        var unit: String
        var country: String
        var facility: String
        var status: RiskScoreVarianceStatus

        init(code: String, name: String, threshold: Double, segment: String, externalRef: String, currency: String, priority: Int, unit: String, country: String, facility: String, status: RiskScoreVarianceStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.segment = segment
            self.externalRef = externalRef
            self.currency = currency
            self.priority = priority
            self.unit = unit
            self.country = country
            self.facility = facility
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

        func canMoveTo(_ next: RiskScoreVarianceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
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
                switch next {
                case .done:
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

        func moveTo(_ next: RiskScoreVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedVolume() -> Double {
            return ((threshold + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreVariance {
            return RiskScoreVariance(
                code: code,
                name: name,
                threshold: threshold,
                segment: segment,
                externalRef: externalRef,
                currency: currency,
                priority: priority,
                unit: unit,
                country: country,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a risk score variance in status new.
    static func newRiskScoreVariance(_ code: String, name: String) -> RiskScoreVariance {
        return RiskScoreVariance(
            code: code,
            name: name,
            threshold: 0.0,
            segment: "",
            externalRef: "",
            currency: "",
            priority: 0,
            unit: "",
            country: "",
            facility: "",
            status: RiskScoreVarianceStatus.new
        )
    }
}
