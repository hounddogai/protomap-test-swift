import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy census digest is in its life cycle.
    enum LegacyCensusDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a legacy census digest and its current status.
    final class LegacyCensusDigest {
        var code: String
        var label: String
        var active: Bool
        var expiresAt: Int
        var title: String
        var budget: Double
        var segment: String
        var ownerID: String
        var status: LegacyCensusDigestStatus

        init(code: String, label: String, active: Bool, expiresAt: Int, title: String, budget: Double, segment: String, ownerID: String, status: LegacyCensusDigestStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.expiresAt = expiresAt
            self.title = title
            self.budget = budget
            self.segment = segment
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCensusDigestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LegacyCensusDigestStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LegacyCensusDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy census digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return (Double(expiresAt) * budget * 100).rounded() / 100
        }

        func copyValue() -> LegacyCensusDigest {
            return LegacyCensusDigest(
                code: code,
                label: label,
                active: active,
                expiresAt: expiresAt,
                title: title,
                budget: budget,
                segment: segment,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy census digest in status created.
    static func newLegacyCensusDigest(_ code: String, label: String) -> LegacyCensusDigest {
        return LegacyCensusDigest(
            code: code,
            label: label,
            active: false,
            expiresAt: 0,
            title: "",
            budget: 0.0,
            segment: "",
            ownerID: "",
            status: LegacyCensusDigestStatus.created
        )
    }
}
