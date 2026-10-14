import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance forecast is in its life cycle.
    enum RemittanceForecastStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A remittance forecast as the remittance team keeps it.
    final class RemittanceForecast {
        var code: String
        var name: String
        var diagnosisCode: String
        var attempts: Int
        var batchSize: Int
        var attributes: [String: String]
        var threshold: Double
        var unit: String
        var currency: String
        var graceDays: Int
        var label: String
        var status: RemittanceForecastStatus

        init(code: String, name: String, diagnosisCode: String, attempts: Int, batchSize: Int, attributes: [String: String], threshold: Double, unit: String, currency: String, graceDays: Int, label: String, status: RemittanceForecastStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.attempts = attempts
            self.batchSize = batchSize
            self.attributes = attributes
            self.threshold = threshold
            self.unit = unit
            self.currency = currency
            self.graceDays = graceDays
            self.label = label
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

        func canMoveTo(_ next: RemittanceForecastStatus) -> Bool {
            switch status {
            case .new:
                return next == RemittanceForecastStatus.running
            case .queued:
                return next == RemittanceForecastStatus.running
            case .running:
                return next == RemittanceForecastStatus.done
            case .done:
                return next == RemittanceForecastStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveVolume() -> Double {
            return ((Double(graceDays) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceForecast {
            return RemittanceForecast(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                attempts: attempts,
                batchSize: batchSize,
                attributes: attributes,
                threshold: threshold,
                unit: unit,
                currency: currency,
                graceDays: graceDays,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a remittance forecast in status new.
    static func newRemittanceForecast(_ code: String, name: String) -> RemittanceForecast {
        return RemittanceForecast(
            code: code,
            name: name,
            diagnosisCode: "",
            attempts: 0,
            batchSize: 0,
            attributes: [:],
            threshold: 0.0,
            unit: "",
            currency: "",
            graceDays: 0,
            label: "",
            status: RemittanceForecastStatus.new
        )
    }
}
