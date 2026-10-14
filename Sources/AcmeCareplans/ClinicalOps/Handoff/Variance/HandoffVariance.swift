import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff variance is in its life cycle.
    enum HandoffVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A handoff variance. Its code is unique within a tenant.
    final class HandoffVariance {
        var code: String
        var label: String
        var quantity: Int
        var minimum: Double
        var externalRef: String
        var diagnosisCode: String
        var version: Int
        var country: String
        var name: String
        var status: HandoffVarianceStatus

        init(code: String, label: String, quantity: Int, minimum: Double, externalRef: String, diagnosisCode: String, version: Int, country: String, name: String, status: HandoffVarianceStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.minimum = minimum
            self.externalRef = externalRef
            self.diagnosisCode = diagnosisCode
            self.version = version
            self.country = country
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: HandoffVarianceStatus) -> Bool {
            switch status {
            case .planned:
                return next == HandoffVarianceStatus.cancelled
            case .scheduled:
                return next == HandoffVarianceStatus.inProgress || next == HandoffVarianceStatus.cancelled
            case .inProgress:
                return next == HandoffVarianceStatus.cancelled
            case .completed:
                return next == HandoffVarianceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("handoff variance") \(code)"
        }

        func netValue() -> Double {
            return (Double(version) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> HandoffVariance {
            return HandoffVariance(
                code: code,
                label: label,
                quantity: quantity,
                minimum: minimum,
                externalRef: externalRef,
                diagnosisCode: diagnosisCode,
                version: version,
                country: country,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a handoff variance in status planned.
    static func newHandoffVariance(_ code: String, label: String) -> HandoffVariance {
        return HandoffVariance(
            code: code,
            label: label,
            quantity: 0,
            minimum: 0.0,
            externalRef: "",
            diagnosisCode: "",
            version: 0,
            country: "",
            name: "",
            status: HandoffVarianceStatus.planned
        )
    }
}
