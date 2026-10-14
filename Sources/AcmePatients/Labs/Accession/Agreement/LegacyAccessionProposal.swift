import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy accession proposal is in its life cycle.
    enum LegacyAccessionProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A legacy accession proposal as the accession team keeps it.
    final class LegacyAccessionProposal {
        var code: String
        var name: String
        var floorValue: Double
        var tags: [String]
        var cost: Double
        var label: String
        var dosageMg: Double
        var windowDays: Int
        var score: Double
        var status: LegacyAccessionProposalStatus

        init(code: String, name: String, floorValue: Double, tags: [String], cost: Double, label: String, dosageMg: Double, windowDays: Int, score: Double, status: LegacyAccessionProposalStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.tags = tags
            self.cost = cost
            self.label = label
            self.dosageMg = dosageMg
            self.windowDays = windowDays
            self.score = score
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

        func canMoveTo(_ next: LegacyAccessionProposalStatus) -> Bool {
            switch status {
            case .requested:
                return next == LegacyAccessionProposalStatus.expired
            case .granted:
                return next == LegacyAccessionProposalStatus.revoked || next == LegacyAccessionProposalStatus.expired
            case .revoked:
                return next == LegacyAccessionProposalStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAccessionProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy accession proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy accession proposal") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return (score * floorValue * 100).rounded() / 100
        }

        func copyValue() -> LegacyAccessionProposal {
            return LegacyAccessionProposal(
                code: code,
                name: name,
                floorValue: floorValue,
                tags: tags,
                cost: cost,
                label: label,
                dosageMg: dosageMg,
                windowDays: windowDays,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy accession proposal in status requested.
    static func newLegacyAccessionProposal(_ code: String, name: String) -> LegacyAccessionProposal {
        return LegacyAccessionProposal(
            code: code,
            name: name,
            floorValue: 0.0,
            tags: [],
            cost: 0.0,
            label: "",
            dosageMg: 0.0,
            windowDays: 0,
            score: 0.0,
            status: LegacyAccessionProposalStatus.requested
        )
    }
}
