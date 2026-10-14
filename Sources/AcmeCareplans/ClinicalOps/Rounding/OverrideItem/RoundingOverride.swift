import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding override is in its life cycle.
    enum RoundingOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rounding override. Its code is unique within a tenant.
    final class RoundingOverride {
        var code: String
        var label: String
        var summary: String
        var category: String
        var ratio: Double
        var endsAt: Int
        var checksum: String
        var status: RoundingOverrideStatus

        init(code: String, label: String, summary: String, category: String, ratio: Double, endsAt: Int, checksum: String, status: RoundingOverrideStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.category = category
            self.ratio = ratio
            self.endsAt = endsAt
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RoundingOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RoundingOverrideStatus.rejected || next == RoundingOverrideStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RoundingOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("rounding override") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(endsAt) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> RoundingOverride {
            return RoundingOverride(
                code: code,
                label: label,
                summary: summary,
                category: category,
                ratio: ratio,
                endsAt: endsAt,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rounding override in status proposed.
    static func newRoundingOverride(_ code: String, label: String) -> RoundingOverride {
        return RoundingOverride(
            code: code,
            label: label,
            summary: "",
            category: "",
            ratio: 0.0,
            endsAt: 0,
            checksum: "",
            status: RoundingOverrideStatus.proposed
        )
    }
}
