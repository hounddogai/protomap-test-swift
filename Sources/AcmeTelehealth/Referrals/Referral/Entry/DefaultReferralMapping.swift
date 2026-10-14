import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default referral mapping is in its life cycle.
    enum DefaultReferralMappingStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a default referral mapping and its current status.
    final class DefaultReferralMapping {
        var code: String
        var label: String
        var region: String
        var copay: Double
        var externalRef: String
        var status: DefaultReferralMappingStatus

        init(code: String, label: String, region: String, copay: Double, externalRef: String, status: DefaultReferralMappingStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.copay = copay
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

        func canMoveTo(_ next: DefaultReferralMappingStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == DefaultReferralMappingStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultReferralMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default referral mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> DefaultReferralMapping {
            return DefaultReferralMapping(
                code: code,
                label: label,
                region: region,
                copay: copay,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a default referral mapping in status open.
    static func newDefaultReferralMapping(_ code: String, label: String) -> DefaultReferralMapping {
        return DefaultReferralMapping(
            code: code,
            label: label,
            region: "",
            copay: 0.0,
            externalRef: "",
            status: DefaultReferralMappingStatus.`open`
        )
    }
}
