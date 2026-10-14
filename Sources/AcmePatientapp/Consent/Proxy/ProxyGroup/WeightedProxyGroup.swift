import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted proxy group is in its life cycle.
    enum WeightedProxyGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted proxy group as the proxy team keeps it.
    final class WeightedProxyGroup {
        var code: String
        var title: String
        var specialty: String
        var checksum: String
        var durationMinutes: Int
        var maximum: Double
        var status: WeightedProxyGroupStatus

        init(code: String, title: String, specialty: String, checksum: String, durationMinutes: Int, maximum: Double, status: WeightedProxyGroupStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.checksum = checksum
            self.durationMinutes = durationMinutes
            self.maximum = maximum
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

        func canMoveTo(_ next: WeightedProxyGroupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == WeightedProxyGroupStatus.reopened || next == WeightedProxyGroupStatus.archived
            case .reopened:
                return next == WeightedProxyGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedProxyGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted proxy group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return (maximum * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> WeightedProxyGroup {
            return WeightedProxyGroup(
                code: code,
                title: title,
                specialty: specialty,
                checksum: checksum,
                durationMinutes: durationMinutes,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted proxy group in status open.
    static func newWeightedProxyGroup(_ code: String, title: String) -> WeightedProxyGroup {
        return WeightedProxyGroup(
            code: code,
            title: title,
            specialty: "",
            checksum: "",
            durationMinutes: 0,
            maximum: 0.0,
            status: WeightedProxyGroupStatus.`open`
        )
    }
}
