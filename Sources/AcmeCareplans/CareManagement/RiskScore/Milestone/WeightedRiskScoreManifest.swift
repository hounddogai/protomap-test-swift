import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted risk score manifest is in its life cycle.
    enum WeightedRiskScoreManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted risk score manifest. Its code is unique within a tenant.
    final class WeightedRiskScoreManifest {
        var code: String
        var label: String
        var payer: String
        var facility: String
        var limit: Int
        var name: String
        var budget: Double
        var status: WeightedRiskScoreManifestStatus

        init(code: String, label: String, payer: String, facility: String, limit: Int, name: String, budget: Double, status: WeightedRiskScoreManifestStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.facility = facility
            self.limit = limit
            self.name = name
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedRiskScoreManifestStatus) -> Bool {
            switch status {
            case .draft:
                return next == WeightedRiskScoreManifestStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == WeightedRiskScoreManifestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedRiskScoreManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted risk score manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedValue() -> Double {
            return ((Double(limit) - budget) * 100).rounded() / 100
        }

        func copyValue() -> WeightedRiskScoreManifest {
            return WeightedRiskScoreManifest(
                code: code,
                label: label,
                payer: payer,
                facility: facility,
                limit: limit,
                name: name,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted risk score manifest in status draft.
    static func newWeightedRiskScoreManifest(_ code: String, label: String) -> WeightedRiskScoreManifest {
        return WeightedRiskScoreManifest(
            code: code,
            label: label,
            payer: "",
            facility: "",
            limit: 0,
            name: "",
            budget: 0.0,
            status: WeightedRiskScoreManifestStatus.draft
        )
    }
}
