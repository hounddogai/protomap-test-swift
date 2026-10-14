import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive isolation policy is in its life cycle.
    enum AdaptiveIsolationPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive isolation policy. Its code is unique within a tenant.
    final class AdaptiveIsolationPolicy {
        var code: String
        var label: String
        var encounterID: String
        var floorValue: Double
        var maximum: Double
        var ward: String
        var channel: String
        var status: AdaptiveIsolationPolicyStatus

        init(code: String, label: String, encounterID: String, floorValue: Double, maximum: Double, ward: String, channel: String, status: AdaptiveIsolationPolicyStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.floorValue = floorValue
            self.maximum = maximum
            self.ward = ward
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveIsolationPolicyStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AdaptiveIsolationPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive isolation policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive isolation policy") \(code)"
        }

        func netTotal() -> Double {
            return (maximum * floorValue * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveIsolationPolicy {
            return AdaptiveIsolationPolicy(
                code: code,
                label: label,
                encounterID: encounterID,
                floorValue: floorValue,
                maximum: maximum,
                ward: ward,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a adaptive isolation policy in status new.
    static func newAdaptiveIsolationPolicy(_ code: String, label: String) -> AdaptiveIsolationPolicy {
        return AdaptiveIsolationPolicy(
            code: code,
            label: label,
            encounterID: "",
            floorValue: 0.0,
            maximum: 0.0,
            ward: "",
            channel: "",
            status: AdaptiveIsolationPolicyStatus.new
        )
    }
}
