import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network rollup is in its life cycle.
    enum NetworkRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A network rollup as the network team keeps it.
    final class NetworkRollup {
        var code: String
        var name: String
        var threshold: Double
        var reviewer: String
        var endsAt: Int
        var region: String
        var specialty: String
        var archived: Bool
        var weight: Double
        var bed: String
        var phone: String
        var status: NetworkRollupStatus

        init(code: String, name: String, threshold: Double, reviewer: String, endsAt: Int, region: String, specialty: String, archived: Bool, weight: Double, bed: String, phone: String, status: NetworkRollupStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.region = region
            self.specialty = specialty
            self.archived = archived
            self.weight = weight
            self.bed = bed
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkRollupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == NetworkRollupStatus.resolved
            case .inReview:
                return next == NetworkRollupStatus.reopened
            case .resolved:
                return next == NetworkRollupStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: NetworkRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveVolume() -> Double {
            return ((threshold - weight) * 100).rounded() / 100
        }

        func copyValue() -> NetworkRollup {
            return NetworkRollup(
                code: code,
                name: name,
                threshold: threshold,
                reviewer: reviewer,
                endsAt: endsAt,
                region: region,
                specialty: specialty,
                archived: archived,
                weight: weight,
                bed: bed,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a network rollup in status open.
    static func newNetworkRollup(_ code: String, name: String) -> NetworkRollup {
        return NetworkRollup(
            code: code,
            name: name,
            threshold: 0.0,
            reviewer: "",
            endsAt: 0,
            region: "",
            specialty: "",
            archived: false,
            weight: 0.0,
            bed: "",
            phone: "",
            status: NetworkRollupStatus.`open`
        )
    }
}
