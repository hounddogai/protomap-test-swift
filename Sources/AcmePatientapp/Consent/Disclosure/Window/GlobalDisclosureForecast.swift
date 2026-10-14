import AcmePlatform
import Foundation

extension Consent {
    /// Where a global disclosure forecast is in its life cycle.
    enum GlobalDisclosureForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A global disclosure forecast as the disclosure team keeps it.
    final class GlobalDisclosureForecast {
        var code: String
        var label: String
        var channel: String
        var diagnosisCode: String
        var approved: Bool
        var procedureCode: String
        var amount: Double
        var createdAt: Int
        var budget: Double
        var clinicianID: String
        var status: GlobalDisclosureForecastStatus

        init(code: String, label: String, channel: String, diagnosisCode: String, approved: Bool, procedureCode: String, amount: Double, createdAt: Int, budget: Double, clinicianID: String, status: GlobalDisclosureForecastStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.diagnosisCode = diagnosisCode
            self.approved = approved
            self.procedureCode = procedureCode
            self.amount = amount
            self.createdAt = createdAt
            self.budget = budget
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: GlobalDisclosureForecastStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalDisclosureForecastStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: GlobalDisclosureForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global disclosure forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netTotal() -> Double {
            return ((Double(createdAt) + amount) * 100).rounded() / 100
        }

        func copyValue() -> GlobalDisclosureForecast {
            return GlobalDisclosureForecast(
                code: code,
                label: label,
                channel: channel,
                diagnosisCode: diagnosisCode,
                approved: approved,
                procedureCode: procedureCode,
                amount: amount,
                createdAt: createdAt,
                budget: budget,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global disclosure forecast in status proposed.
    static func newGlobalDisclosureForecast(_ code: String, label: String) -> GlobalDisclosureForecast {
        return GlobalDisclosureForecast(
            code: code,
            label: label,
            channel: "",
            diagnosisCode: "",
            approved: false,
            procedureCode: "",
            amount: 0.0,
            createdAt: 0,
            budget: 0.0,
            clinicianID: "",
            status: GlobalDisclosureForecastStatus.proposed
        )
    }
}
