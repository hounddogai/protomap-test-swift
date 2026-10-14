import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive discharge plan bundle is in its life cycle.
    enum AdaptiveDischargePlanBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One adaptive discharge plan bundle, with what the planners need to act on it.
    final class AdaptiveDischargePlanBundle {
        var code: String
        var label: String
        var name: String
        var weight: Double
        var version: Int
        var copay: Double
        var encounterID: String
        var contactEmail: String
        var refills: Int
        var status: AdaptiveDischargePlanBundleStatus

        init(code: String, label: String, name: String, weight: Double, version: Int, copay: Double, encounterID: String, contactEmail: String, refills: Int, status: AdaptiveDischargePlanBundleStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.weight = weight
            self.version = version
            self.copay = copay
            self.encounterID = encounterID
            self.contactEmail = contactEmail
            self.refills = refills
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

        func canMoveTo(_ next: AdaptiveDischargePlanBundleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AdaptiveDischargePlanBundleStatus.archived
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

        func moveTo(_ next: AdaptiveDischargePlanBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive discharge plan bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedExposure() -> Double {
            return ((Double(version) - weight) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveDischargePlanBundle {
            return AdaptiveDischargePlanBundle(
                code: code,
                label: label,
                name: name,
                weight: weight,
                version: version,
                copay: copay,
                encounterID: encounterID,
                contactEmail: contactEmail,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive discharge plan bundle in status open.
    static func newAdaptiveDischargePlanBundle(_ code: String, label: String) -> AdaptiveDischargePlanBundle {
        return AdaptiveDischargePlanBundle(
            code: code,
            label: label,
            name: "",
            weight: 0.0,
            version: 0,
            copay: 0.0,
            encounterID: "",
            contactEmail: "",
            refills: 0,
            status: AdaptiveDischargePlanBundleStatus.`open`
        )
    }
}
