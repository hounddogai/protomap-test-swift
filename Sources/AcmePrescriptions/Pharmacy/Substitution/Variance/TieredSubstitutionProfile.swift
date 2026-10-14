import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered substitution profile is in its life cycle.
    enum TieredSubstitutionProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a tiered substitution profile and its current status.
    final class TieredSubstitutionProfile {
        var code: String
        var label: String
        var score: Double
        var startsAt: Int
        var createdAt: Int
        var visible: Bool
        var summary: String
        var source: String
        var status: TieredSubstitutionProfileStatus

        init(code: String, label: String, score: Double, startsAt: Int, createdAt: Int, visible: Bool, summary: String, source: String, status: TieredSubstitutionProfileStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.startsAt = startsAt
            self.createdAt = createdAt
            self.visible = visible
            self.summary = summary
            self.source = source
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

        func canMoveTo(_ next: TieredSubstitutionProfileStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
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

        func moveTo(_ next: TieredSubstitutionProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered substitution profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedValue() -> Double {
            return ((Double(createdAt) + score) * 100).rounded() / 100
        }

        func copyValue() -> TieredSubstitutionProfile {
            return TieredSubstitutionProfile(
                code: code,
                label: label,
                score: score,
                startsAt: startsAt,
                createdAt: createdAt,
                visible: visible,
                summary: summary,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered substitution profile in status requested.
    static func newTieredSubstitutionProfile(_ code: String, label: String) -> TieredSubstitutionProfile {
        return TieredSubstitutionProfile(
            code: code,
            label: label,
            score: 0.0,
            startsAt: 0,
            createdAt: 0,
            visible: false,
            summary: "",
            source: "",
            status: TieredSubstitutionProfileStatus.requested
        )
    }
}
