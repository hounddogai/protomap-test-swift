import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall tier is in its life cycle.
    enum RecallTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A recall tier. Its code is unique within a tenant.
    final class RecallTier {
        var code: String
        var label: String
        var discount: Double
        var summary: String
        var reviewer: String
        var endsAt: Int
        var specialty: String
        var status: RecallTierStatus

        init(code: String, label: String, discount: Double, summary: String, reviewer: String, endsAt: Int, specialty: String, status: RecallTierStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.summary = summary
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.specialty = specialty
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

        func canMoveTo(_ next: RecallTierStatus) -> Bool {
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
                return next == RecallTierStatus.revoked || next == RecallTierStatus.expired
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

        func moveTo(_ next: RecallTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(endsAt) + discount) * 100).rounded() / 100
        }

        func copyValue() -> RecallTier {
            return RecallTier(
                code: code,
                label: label,
                discount: discount,
                summary: summary,
                reviewer: reviewer,
                endsAt: endsAt,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a recall tier in status requested.
    static func newRecallTier(_ code: String, label: String) -> RecallTier {
        return RecallTier(
            code: code,
            label: label,
            discount: 0.0,
            summary: "",
            reviewer: "",
            endsAt: 0,
            specialty: "",
            status: RecallTierStatus.requested
        )
    }
}
