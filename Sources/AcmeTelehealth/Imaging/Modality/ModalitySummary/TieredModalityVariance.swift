import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered modality variance is in its life cycle.
    enum TieredModalityVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a tiered modality variance and its current status.
    final class TieredModalityVariance {
        var code: String
        var name: String
        var country: String
        var priority: Int
        var unit: String
        var diagnosisCode: String
        var status: TieredModalityVarianceStatus

        init(code: String, name: String, country: String, priority: Int, unit: String, diagnosisCode: String, status: TieredModalityVarianceStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.priority = priority
            self.unit = unit
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: TieredModalityVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredModalityVarianceStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == TieredModalityVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredModalityVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered modality variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> TieredModalityVariance {
            return TieredModalityVariance(
                code: code,
                name: name,
                country: country,
                priority: priority,
                unit: unit,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered modality variance in status proposed.
    static func newTieredModalityVariance(_ code: String, name: String) -> TieredModalityVariance {
        return TieredModalityVariance(
            code: code,
            name: name,
            country: "",
            priority: 0,
            unit: "",
            diagnosisCode: "",
            status: TieredModalityVarianceStatus.proposed
        )
    }
}
