import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary denial metric is in its life cycle.
    enum PrimaryDenialMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary denial metric as the denial team keeps it.
    final class PrimaryDenialMetric {
        var code: String
        var name: String
        var channel: String
        var maximum: Double
        var expiresAt: Int
        var sequence: Int
        var bed: String
        var priority: Int
        var ownerID: String
        var endsAt: Int
        var country: String
        var status: PrimaryDenialMetricStatus

        init(code: String, name: String, channel: String, maximum: Double, expiresAt: Int, sequence: Int, bed: String, priority: Int, ownerID: String, endsAt: Int, country: String, status: PrimaryDenialMetricStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.maximum = maximum
            self.expiresAt = expiresAt
            self.sequence = sequence
            self.bed = bed
            self.priority = priority
            self.ownerID = ownerID
            self.endsAt = endsAt
            self.country = country
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

        func canMoveTo(_ next: PrimaryDenialMetricStatus) -> Bool {
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
                case .running, .failed:
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

        func moveTo(_ next: PrimaryDenialMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary denial metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary denial metric") \(code)"
        }

        func netExposure() -> Double {
            return (Double(endsAt) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDenialMetric {
            return PrimaryDenialMetric(
                code: code,
                name: name,
                channel: channel,
                maximum: maximum,
                expiresAt: expiresAt,
                sequence: sequence,
                bed: bed,
                priority: priority,
                ownerID: ownerID,
                endsAt: endsAt,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary denial metric in status new.
    static func newPrimaryDenialMetric(_ code: String, name: String) -> PrimaryDenialMetric {
        return PrimaryDenialMetric(
            code: code,
            name: name,
            channel: "",
            maximum: 0.0,
            expiresAt: 0,
            sequence: 0,
            bed: "",
            priority: 0,
            ownerID: "",
            endsAt: 0,
            country: "",
            status: PrimaryDenialMetricStatus.new
        )
    }
}
