import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary threshold is in its life cycle.
    enum FormularyThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A formulary threshold. Its code is unique within a tenant.
    final class FormularyThreshold {
        var code: String
        var name: String
        var limit: Int
        var batchSize: Int
        var unit: String
        var currency: String
        var weight: Double
        var status: FormularyThresholdStatus

        init(code: String, name: String, limit: Int, batchSize: Int, unit: String, currency: String, weight: Double, status: FormularyThresholdStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.batchSize = batchSize
            self.unit = unit
            self.currency = currency
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FormularyThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FormularyThresholdStatus.resolved
            case .inReview:
                return next == FormularyThresholdStatus.resolved
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: FormularyThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedValue() -> Double {
            return ((Double(limit) - weight) * 100).rounded() / 100
        }

        func copyValue() -> FormularyThreshold {
            return FormularyThreshold(
                code: code,
                name: name,
                limit: limit,
                batchSize: batchSize,
                unit: unit,
                currency: currency,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a formulary threshold in status open.
    static func newFormularyThreshold(_ code: String, name: String) -> FormularyThreshold {
        return FormularyThreshold(
            code: code,
            name: name,
            limit: 0,
            batchSize: 0,
            unit: "",
            currency: "",
            weight: 0.0,
            status: FormularyThresholdStatus.`open`
        )
    }
}
