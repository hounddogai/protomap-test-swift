import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted consent form rollup is in its life cycle.
    enum WeightedConsentFormRollupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted consent form rollup as the consent form team keeps it.
    final class WeightedConsentFormRollup {
        var code: String
        var title: String
        var durationMinutes: Int
        var margin: Double
        var channel: String
        var region: String
        var version: Int
        var status: WeightedConsentFormRollupStatus

        init(code: String, title: String, durationMinutes: Int, margin: Double, channel: String, region: String, version: Int, status: WeightedConsentFormRollupStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.margin = margin
            self.channel = channel
            self.region = region
            self.version = version
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

        func canMoveTo(_ next: WeightedConsentFormRollupStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedConsentFormRollupStatus.published || next == WeightedConsentFormRollupStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WeightedConsentFormRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted consent form rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("weighted consent form rollup") \(code)"
        }

        func netTotal() -> Double {
            return (Double(durationMinutes) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> WeightedConsentFormRollup {
            return WeightedConsentFormRollup(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                margin: margin,
                channel: channel,
                region: region,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted consent form rollup in status created.
    static func newWeightedConsentFormRollup(_ code: String, title: String) -> WeightedConsentFormRollup {
        return WeightedConsentFormRollup(
            code: code,
            title: title,
            durationMinutes: 0,
            margin: 0.0,
            channel: "",
            region: "",
            version: 0,
            status: WeightedConsentFormRollupStatus.created
        )
    }
}
