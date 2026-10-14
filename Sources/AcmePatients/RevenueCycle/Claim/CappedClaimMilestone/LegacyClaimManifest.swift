import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy claim manifest is in its life cycle.
    enum LegacyClaimManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy claim manifest as the claim team keeps it.
    final class LegacyClaimManifest {
        var code: String
        var label: String
        var reviewer: String
        var channel: String
        var encounterID: String
        var maximum: Double
        var ownerID: String
        var specialty: String
        var externalRef: String
        var status: LegacyClaimManifestStatus

        init(code: String, label: String, reviewer: String, channel: String, encounterID: String, maximum: Double, ownerID: String, specialty: String, externalRef: String, status: LegacyClaimManifestStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.channel = channel
            self.encounterID = encounterID
            self.maximum = maximum
            self.ownerID = ownerID
            self.specialty = specialty
            self.externalRef = externalRef
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

        func canMoveTo(_ next: LegacyClaimManifestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyClaimManifestStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyClaimManifestStatus.archived
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

        func moveTo(_ next: LegacyClaimManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy claim manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> LegacyClaimManifest {
            return LegacyClaimManifest(
                code: code,
                label: label,
                reviewer: reviewer,
                channel: channel,
                encounterID: encounterID,
                maximum: maximum,
                ownerID: ownerID,
                specialty: specialty,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy claim manifest in status open.
    static func newLegacyClaimManifest(_ code: String, label: String) -> LegacyClaimManifest {
        return LegacyClaimManifest(
            code: code,
            label: label,
            reviewer: "",
            channel: "",
            encounterID: "",
            maximum: 0.0,
            ownerID: "",
            specialty: "",
            externalRef: "",
            status: LegacyClaimManifestStatus.`open`
        )
    }
}
