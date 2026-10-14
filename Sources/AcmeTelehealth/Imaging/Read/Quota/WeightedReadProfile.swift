import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted read profile is in its life cycle.
    enum WeightedReadProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted read profile. Its code is unique within a tenant.
    final class WeightedReadProfile {
        var code: String
        var name: String
        var category: String
        var rate: Double
        var externalRef: String
        var status: WeightedReadProfileStatus

        init(code: String, name: String, category: String, rate: Double, externalRef: String, status: WeightedReadProfileStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.rate = rate
            self.externalRef = externalRef
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

        func canMoveTo(_ next: WeightedReadProfileStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedReadProfileStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WeightedReadProfileStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedReadProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted read profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> WeightedReadProfile {
            return WeightedReadProfile(
                code: code,
                name: name,
                category: category,
                rate: rate,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a weighted read profile in status requested.
    static func newWeightedReadProfile(_ code: String, name: String) -> WeightedReadProfile {
        return WeightedReadProfile(
            code: code,
            name: name,
            category: "",
            rate: 0.0,
            externalRef: "",
            status: WeightedReadProfileStatus.requested
        )
    }
}
