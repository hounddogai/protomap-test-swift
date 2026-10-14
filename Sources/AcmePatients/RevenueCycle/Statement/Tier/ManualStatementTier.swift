import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual statement tier is in its life cycle.
    enum ManualStatementTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One manual statement tier, with what the planners need to act on it.
    final class ManualStatementTier {
        var code: String
        var label: String
        var threshold: Double
        var name: String
        var country: String
        var durationMinutes: Int
        var version: Int
        var status: ManualStatementTierStatus

        init(code: String, label: String, threshold: Double, name: String, country: String, durationMinutes: Int, version: Int, status: ManualStatementTierStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.name = name
            self.country = country
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: ManualStatementTierStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualStatementTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual statement tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return ((threshold + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ManualStatementTier {
            return ManualStatementTier(
                code: code,
                label: label,
                threshold: threshold,
                name: name,
                country: country,
                durationMinutes: durationMinutes,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual statement tier in status created.
    static func newManualStatementTier(_ code: String, label: String) -> ManualStatementTier {
        return ManualStatementTier(
            code: code,
            label: label,
            threshold: 0.0,
            name: "",
            country: "",
            durationMinutes: 0,
            version: 0,
            status: ManualStatementTierStatus.created
        )
    }
}
