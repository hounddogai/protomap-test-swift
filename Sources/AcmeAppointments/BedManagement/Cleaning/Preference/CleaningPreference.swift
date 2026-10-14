import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning preference is in its life cycle.
    enum CleaningPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A cleaning preference. Its code is unique within a tenant.
    final class CleaningPreference {
        var code: String
        var name: String
        var label: String
        var margin: Double
        var country: String
        var source: String
        var segment: String
        var channel: String
        var ceiling: Double
        var copay: Double
        var ownerID: String
        var status: CleaningPreferenceStatus

        init(code: String, name: String, label: String, margin: Double, country: String, source: String, segment: String, channel: String, ceiling: Double, copay: Double, ownerID: String, status: CleaningPreferenceStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.margin = margin
            self.country = country
            self.source = source
            self.segment = segment
            self.channel = channel
            self.ceiling = ceiling
            self.copay = copay
            self.ownerID = ownerID
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

        func canMoveTo(_ next: CleaningPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CleaningPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("cleaning preference") \(code)"
        }

        func projectedLoad() -> Double {
            return (ceiling * margin * 100).rounded() / 100
        }

        func copyValue() -> CleaningPreference {
            return CleaningPreference(
                code: code,
                name: name,
                label: label,
                margin: margin,
                country: country,
                source: source,
                segment: segment,
                channel: channel,
                ceiling: ceiling,
                copay: copay,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a cleaning preference in status proposed.
    static func newCleaningPreference(_ code: String, name: String) -> CleaningPreference {
        return CleaningPreference(
            code: code,
            name: name,
            label: "",
            margin: 0.0,
            country: "",
            source: "",
            segment: "",
            channel: "",
            ceiling: 0.0,
            copay: 0.0,
            ownerID: "",
            status: CleaningPreferenceStatus.proposed
        )
    }
}
