import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy modality preference is in its life cycle.
    enum LegacyModalityPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A legacy modality preference. Its code is unique within a tenant.
    final class LegacyModalityPreference {
        var code: String
        var title: String
        var revision: Int
        var amount: Double
        var windowDays: Int
        var summary: String
        var externalRef: String
        var channel: String
        var capacity: Int
        var status: LegacyModalityPreferenceStatus

        init(code: String, title: String, revision: Int, amount: Double, windowDays: Int, summary: String, externalRef: String, channel: String, capacity: Int, status: LegacyModalityPreferenceStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.amount = amount
            self.windowDays = windowDays
            self.summary = summary
            self.externalRef = externalRef
            self.channel = channel
            self.capacity = capacity
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

        func canMoveTo(_ next: LegacyModalityPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                return next == LegacyModalityPreferenceStatus.granted
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

        func moveTo(_ next: LegacyModalityPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy modality preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("legacy modality preference") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(capacity) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyModalityPreference {
            return LegacyModalityPreference(
                code: code,
                title: title,
                revision: revision,
                amount: amount,
                windowDays: windowDays,
                summary: summary,
                externalRef: externalRef,
                channel: channel,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy modality preference in status requested.
    static func newLegacyModalityPreference(_ code: String, title: String) -> LegacyModalityPreference {
        return LegacyModalityPreference(
            code: code,
            title: title,
            revision: 0,
            amount: 0.0,
            windowDays: 0,
            summary: "",
            externalRef: "",
            channel: "",
            capacity: 0,
            status: LegacyModalityPreferenceStatus.requested
        )
    }
}
