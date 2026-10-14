import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy courier estimate is in its life cycle.
    enum LegacyCourierEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a legacy courier estimate and its current status.
    final class LegacyCourierEstimate {
        var code: String
        var name: String
        var channel: String
        var budget: Double
        var approved: Bool
        var dosageMg: Double
        var attributes: [String: String]
        var clinicianID: String
        var status: LegacyCourierEstimateStatus

        init(code: String, name: String, channel: String, budget: Double, approved: Bool, dosageMg: Double, attributes: [String: String], clinicianID: String, status: LegacyCourierEstimateStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.budget = budget
            self.approved = approved
            self.dosageMg = dosageMg
            self.attributes = attributes
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCourierEstimateStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LegacyCourierEstimateStatus.published || next == LegacyCourierEstimateStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LegacyCourierEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy courier estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func projectedTotal() -> Double {
            return ((dosageMg - budget) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCourierEstimate {
            return LegacyCourierEstimate(
                code: code,
                name: name,
                channel: channel,
                budget: budget,
                approved: approved,
                dosageMg: dosageMg,
                attributes: attributes,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy courier estimate in status created.
    static func newLegacyCourierEstimate(_ code: String, name: String) -> LegacyCourierEstimate {
        return LegacyCourierEstimate(
            code: code,
            name: name,
            channel: "",
            budget: 0.0,
            approved: false,
            dosageMg: 0.0,
            attributes: [:],
            clinicianID: "",
            status: LegacyCourierEstimateStatus.created
        )
    }
}
