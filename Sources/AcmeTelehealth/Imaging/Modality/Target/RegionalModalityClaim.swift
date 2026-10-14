import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional modality claim is in its life cycle.
    enum RegionalModalityClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A regional modality claim. Its code is unique within a tenant.
    final class RegionalModalityClaim {
        var code: String
        var label: String
        var summary: String
        var capacity: Int
        var expiresAt: Int
        var channel: String
        var status: RegionalModalityClaimStatus

        init(code: String, label: String, summary: String, capacity: Int, expiresAt: Int, channel: String, status: RegionalModalityClaimStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.capacity = capacity
            self.expiresAt = expiresAt
            self.channel = channel
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

        func canMoveTo(_ next: RegionalModalityClaimStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RegionalModalityClaimStatus.rejected || next == RegionalModalityClaimStatus.withdrawn
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

        func moveTo(_ next: RegionalModalityClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional modality claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("regional modality claim") \(code)"
        }

        func effectiveValue() -> Double {
            return ((Double(expiresAt) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalModalityClaim {
            return RegionalModalityClaim(
                code: code,
                label: label,
                summary: summary,
                capacity: capacity,
                expiresAt: expiresAt,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a regional modality claim in status proposed.
    static func newRegionalModalityClaim(_ code: String, label: String) -> RegionalModalityClaim {
        return RegionalModalityClaim(
            code: code,
            label: label,
            summary: "",
            capacity: 0,
            expiresAt: 0,
            channel: "",
            status: RegionalModalityClaimStatus.proposed
        )
    }
}
