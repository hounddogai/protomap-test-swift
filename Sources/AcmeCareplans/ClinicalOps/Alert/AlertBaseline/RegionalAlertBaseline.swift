import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional alert baseline is in its life cycle.
    enum RegionalAlertBaselineStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a regional alert baseline and its current status.
    final class RegionalAlertBaseline {
        var code: String
        var label: String
        var active: Bool
        var procedureCode: String
        var country: String
        var endsAt: Int
        var encounterID: String
        var status: RegionalAlertBaselineStatus

        init(code: String, label: String, active: Bool, procedureCode: String, country: String, endsAt: Int, encounterID: String, status: RegionalAlertBaselineStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.procedureCode = procedureCode
            self.country = country
            self.endsAt = endsAt
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalAlertBaselineStatus) -> Bool {
            switch status {
            case .idle:
                return next == RegionalAlertBaselineStatus.warming
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RegionalAlertBaselineStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAlertBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional alert baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> RegionalAlertBaseline {
            return RegionalAlertBaseline(
                code: code,
                label: label,
                active: active,
                procedureCode: procedureCode,
                country: country,
                endsAt: endsAt,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional alert baseline in status idle.
    static func newRegionalAlertBaseline(_ code: String, label: String) -> RegionalAlertBaseline {
        return RegionalAlertBaseline(
            code: code,
            label: label,
            active: false,
            procedureCode: "",
            country: "",
            endsAt: 0,
            encounterID: "",
            status: RegionalAlertBaselineStatus.idle
        )
    }
}
