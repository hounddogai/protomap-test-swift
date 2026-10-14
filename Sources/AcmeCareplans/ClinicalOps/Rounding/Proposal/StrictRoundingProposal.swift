import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict rounding proposal is in its life cycle.
    enum StrictRoundingProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A strict rounding proposal. Its code is unique within a tenant.
    final class StrictRoundingProposal {
        var code: String
        var title: String
        var currency: String
        var floorValue: Double
        var createdAt: Int
        var locale: String
        var status: StrictRoundingProposalStatus

        init(code: String, title: String, currency: String, floorValue: Double, createdAt: Int, locale: String, status: StrictRoundingProposalStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.floorValue = floorValue
            self.createdAt = createdAt
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictRoundingProposalStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: StrictRoundingProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict rounding proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return ((floorValue + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictRoundingProposal {
            return StrictRoundingProposal(
                code: code,
                title: title,
                currency: currency,
                floorValue: floorValue,
                createdAt: createdAt,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict rounding proposal in status requested.
    static func newStrictRoundingProposal(_ code: String, title: String) -> StrictRoundingProposal {
        return StrictRoundingProposal(
            code: code,
            title: title,
            currency: "",
            floorValue: 0.0,
            createdAt: 0,
            locale: "",
            status: StrictRoundingProposalStatus.requested
        )
    }
}
