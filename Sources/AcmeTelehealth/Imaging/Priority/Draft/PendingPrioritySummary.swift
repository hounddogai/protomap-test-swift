import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending priority summary is in its life cycle.
    enum PendingPrioritySummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a pending priority summary and its current status.
    final class PendingPrioritySummary {
        var code: String
        var name: String
        var createdAt: Int
        var floorValue: Double
        var summary: String
        var diagnosisCode: String
        var maximum: Double
        var status: PendingPrioritySummaryStatus

        init(code: String, name: String, createdAt: Int, floorValue: Double, summary: String, diagnosisCode: String, maximum: Double, status: PendingPrioritySummaryStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.floorValue = floorValue
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.maximum = maximum
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

        func canMoveTo(_ next: PendingPrioritySummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == PendingPrioritySummaryStatus.revoked
            case .granted:
                return next == PendingPrioritySummaryStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PendingPrioritySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending priority summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netLoad() -> Double {
            return ((maximum - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingPrioritySummary {
            return PendingPrioritySummary(
                code: code,
                name: name,
                createdAt: createdAt,
                floorValue: floorValue,
                summary: summary,
                diagnosisCode: diagnosisCode,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending priority summary in status requested.
    static func newPendingPrioritySummary(_ code: String, name: String) -> PendingPrioritySummary {
        return PendingPrioritySummary(
            code: code,
            name: name,
            createdAt: 0,
            floorValue: 0.0,
            summary: "",
            diagnosisCode: "",
            maximum: 0.0,
            status: PendingPrioritySummaryStatus.requested
        )
    }
}
