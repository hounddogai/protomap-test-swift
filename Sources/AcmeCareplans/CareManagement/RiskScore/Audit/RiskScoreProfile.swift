import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score profile is in its life cycle.
    enum RiskScoreProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a risk score profile and its current status.
    final class RiskScoreProfile {
        var code: String
        var name: String
        var encounterID: String
        var segment: String
        var version: Int
        var title: String
        var weight: Double
        var summary: String
        var copay: Double
        var budget: Double
        var status: RiskScoreProfileStatus

        init(code: String, name: String, encounterID: String, segment: String, version: Int, title: String, weight: Double, summary: String, copay: Double, budget: Double, status: RiskScoreProfileStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.segment = segment
            self.version = version
            self.title = title
            self.weight = weight
            self.summary = summary
            self.copay = copay
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

        func canMoveTo(_ next: RiskScoreProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RiskScoreProfileStatus.closed
            case .active:
                return next == RiskScoreProfileStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RiskScoreProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return ((copay + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreProfile {
            return RiskScoreProfile(
                code: code,
                name: name,
                encounterID: encounterID,
                segment: segment,
                version: version,
                title: title,
                weight: weight,
                summary: summary,
                copay: copay,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a risk score profile in status draft.
    static func newRiskScoreProfile(_ code: String, name: String) -> RiskScoreProfile {
        return RiskScoreProfile(
            code: code,
            name: name,
            encounterID: "",
            segment: "",
            version: 0,
            title: "",
            weight: 0.0,
            summary: "",
            copay: 0.0,
            budget: 0.0,
            status: RiskScoreProfileStatus.draft
        )
    }
}
