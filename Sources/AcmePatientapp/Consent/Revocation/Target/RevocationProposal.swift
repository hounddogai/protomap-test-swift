import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation proposal is in its life cycle.
    enum RevocationProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A revocation proposal. Its code is unique within a tenant.
    final class RevocationProposal {
        var code: String
        var label: String
        var active: Bool
        var externalRef: String
        var version: Int
        var ratio: Double
        var createdAt: Int
        var startsAt: Int
        var margin: Double
        var discount: Double
        var ward: String
        var status: RevocationProposalStatus

        init(code: String, label: String, active: Bool, externalRef: String, version: Int, ratio: Double, createdAt: Int, startsAt: Int, margin: Double, discount: Double, ward: String, status: RevocationProposalStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.externalRef = externalRef
            self.version = version
            self.ratio = ratio
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.margin = margin
            self.discount = discount
            self.ward = ward
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

        func canMoveTo(_ next: RevocationProposalStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RevocationProposalStatus.resolved
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RevocationProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("revocation proposal") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(startsAt) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> RevocationProposal {
            return RevocationProposal(
                code: code,
                label: label,
                active: active,
                externalRef: externalRef,
                version: version,
                ratio: ratio,
                createdAt: createdAt,
                startsAt: startsAt,
                margin: margin,
                discount: discount,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a revocation proposal in status open.
    static func newRevocationProposal(_ code: String, label: String) -> RevocationProposal {
        return RevocationProposal(
            code: code,
            label: label,
            active: false,
            externalRef: "",
            version: 0,
            ratio: 0.0,
            createdAt: 0,
            startsAt: 0,
            margin: 0.0,
            discount: 0.0,
            ward: "",
            status: RevocationProposalStatus.`open`
        )
    }
}
