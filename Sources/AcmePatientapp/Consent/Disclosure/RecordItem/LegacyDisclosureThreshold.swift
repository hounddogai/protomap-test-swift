import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy disclosure threshold is in its life cycle.
    enum LegacyDisclosureThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy disclosure threshold. Its code is unique within a tenant.
    final class LegacyDisclosureThreshold {
        var code: String
        var label: String
        var encounterID: String
        var allergy: String
        var source: String
        var rate: Double
        var status: LegacyDisclosureThresholdStatus

        init(code: String, label: String, encounterID: String, allergy: String, source: String, rate: Double, status: LegacyDisclosureThresholdStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.allergy = allergy
            self.source = source
            self.rate = rate
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

        func canMoveTo(_ next: LegacyDisclosureThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyDisclosureThresholdStatus.resolved || next == LegacyDisclosureThresholdStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyDisclosureThresholdStatus.reopened || next == LegacyDisclosureThresholdStatus.archived
            case .reopened:
                return next == LegacyDisclosureThresholdStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyDisclosureThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy disclosure threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> LegacyDisclosureThreshold {
            return LegacyDisclosureThreshold(
                code: code,
                label: label,
                encounterID: encounterID,
                allergy: allergy,
                source: source,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a legacy disclosure threshold in status open.
    static func newLegacyDisclosureThreshold(_ code: String, label: String) -> LegacyDisclosureThreshold {
        return LegacyDisclosureThreshold(
            code: code,
            label: label,
            encounterID: "",
            allergy: "",
            source: "",
            rate: 0.0,
            status: LegacyDisclosureThresholdStatus.`open`
        )
    }
}
