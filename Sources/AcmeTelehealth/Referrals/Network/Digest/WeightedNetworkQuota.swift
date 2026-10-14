import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted network quota is in its life cycle.
    enum WeightedNetworkQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One weighted network quota, with what the planners need to act on it.
    final class WeightedNetworkQuota {
        var code: String
        var name: String
        var specialty: String
        var margin: Double
        var checksum: String
        var bed: String
        var encounterID: String
        var capacity: Int
        var cost: Double
        var summary: String
        var label: String
        var status: WeightedNetworkQuotaStatus

        init(code: String, name: String, specialty: String, margin: Double, checksum: String, bed: String, encounterID: String, capacity: Int, cost: Double, summary: String, label: String, status: WeightedNetworkQuotaStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.margin = margin
            self.checksum = checksum
            self.bed = bed
            self.encounterID = encounterID
            self.capacity = capacity
            self.cost = cost
            self.summary = summary
            self.label = label
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedNetworkQuotaStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedNetworkQuotaStatus.ready || next == WeightedNetworkQuotaStatus.stopped
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: WeightedNetworkQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted network quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func projectedValue() -> Double {
            return ((cost + margin) * 100).rounded() / 100
        }

        func copyValue() -> WeightedNetworkQuota {
            return WeightedNetworkQuota(
                code: code,
                name: name,
                specialty: specialty,
                margin: margin,
                checksum: checksum,
                bed: bed,
                encounterID: encounterID,
                capacity: capacity,
                cost: cost,
                summary: summary,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted network quota in status idle.
    static func newWeightedNetworkQuota(_ code: String, name: String) -> WeightedNetworkQuota {
        return WeightedNetworkQuota(
            code: code,
            name: name,
            specialty: "",
            margin: 0.0,
            checksum: "",
            bed: "",
            encounterID: "",
            capacity: 0,
            cost: 0.0,
            summary: "",
            label: "",
            status: WeightedNetworkQuotaStatus.idle
        )
    }
}
