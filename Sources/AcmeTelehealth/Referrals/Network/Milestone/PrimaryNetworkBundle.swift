import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary network bundle is in its life cycle.
    enum PrimaryNetworkBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary network bundle as the network team keeps it.
    final class PrimaryNetworkBundle {
        var code: String
        var name: String
        var margin: Double
        var floorValue: Double
        var country: String
        var limit: Int
        var bed: String
        var status: PrimaryNetworkBundleStatus

        init(code: String, name: String, margin: Double, floorValue: Double, country: String, limit: Int, bed: String, status: PrimaryNetworkBundleStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.floorValue = floorValue
            self.country = country
            self.limit = limit
            self.bed = bed
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

        func canMoveTo(_ next: PrimaryNetworkBundleStatus) -> Bool {
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
                return next == PrimaryNetworkBundleStatus.rejected
            case .rejected:
                return next == PrimaryNetworkBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryNetworkBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary network bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveLoad() -> Double {
            return ((margin - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryNetworkBundle {
            return PrimaryNetworkBundle(
                code: code,
                name: name,
                margin: margin,
                floorValue: floorValue,
                country: country,
                limit: limit,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary network bundle in status proposed.
    static func newPrimaryNetworkBundle(_ code: String, name: String) -> PrimaryNetworkBundle {
        return PrimaryNetworkBundle(
            code: code,
            name: name,
            margin: 0.0,
            floorValue: 0.0,
            country: "",
            limit: 0,
            bed: "",
            status: PrimaryNetworkBundleStatus.proposed
        )
    }
}
