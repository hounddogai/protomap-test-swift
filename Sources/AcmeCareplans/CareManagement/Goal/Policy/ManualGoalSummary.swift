import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual goal summary is in its life cycle.
    enum ManualGoalSummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One manual goal summary, with what the planners need to act on it.
    final class ManualGoalSummary {
        var code: String
        var label: String
        var active: Bool
        var region: String
        var specialty: String
        var version: Int
        var currency: String
        var encounterID: String
        var channel: String
        var allergy: String
        var status: ManualGoalSummaryStatus

        init(code: String, label: String, active: Bool, region: String, specialty: String, version: Int, currency: String, encounterID: String, channel: String, allergy: String, status: ManualGoalSummaryStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.region = region
            self.specialty = specialty
            self.version = version
            self.currency = currency
            self.encounterID = encounterID
            self.channel = channel
            self.allergy = allergy
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

        func canMoveTo(_ next: ManualGoalSummaryStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
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

        func moveTo(_ next: ManualGoalSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual goal summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("manual goal summary") \(code)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> ManualGoalSummary {
            return ManualGoalSummary(
                code: code,
                label: label,
                active: active,
                region: region,
                specialty: specialty,
                version: version,
                currency: currency,
                encounterID: encounterID,
                channel: channel,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual goal summary in status proposed.
    static func newManualGoalSummary(_ code: String, label: String) -> ManualGoalSummary {
        return ManualGoalSummary(
            code: code,
            label: label,
            active: false,
            region: "",
            specialty: "",
            version: 0,
            currency: "",
            encounterID: "",
            channel: "",
            allergy: "",
            status: ManualGoalSummaryStatus.proposed
        )
    }
}
