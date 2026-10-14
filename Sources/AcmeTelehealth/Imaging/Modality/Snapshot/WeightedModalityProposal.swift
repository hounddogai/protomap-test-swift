import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted modality proposal is in its life cycle.
    enum WeightedModalityProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted modality proposal as the modality team keeps it.
    final class WeightedModalityProposal {
        var code: String
        var name: String
        var startsAt: Int
        var active: Bool
        var region: String
        var externalRef: String
        var status: WeightedModalityProposalStatus

        init(code: String, name: String, startsAt: Int, active: Bool, region: String, externalRef: String, status: WeightedModalityProposalStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.active = active
            self.region = region
            self.externalRef = externalRef
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

        func canMoveTo(_ next: WeightedModalityProposalStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == WeightedModalityProposalStatus.expired
            case .revoked:
                return next == WeightedModalityProposalStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedModalityProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted modality proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> WeightedModalityProposal {
            return WeightedModalityProposal(
                code: code,
                name: name,
                startsAt: startsAt,
                active: active,
                region: region,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a weighted modality proposal in status requested.
    static func newWeightedModalityProposal(_ code: String, name: String) -> WeightedModalityProposal {
        return WeightedModalityProposal(
            code: code,
            name: name,
            startsAt: 0,
            active: false,
            region: "",
            externalRef: "",
            status: WeightedModalityProposalStatus.requested
        )
    }
}
