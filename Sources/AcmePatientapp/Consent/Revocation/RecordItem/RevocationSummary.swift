import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation summary is in its life cycle.
    enum RevocationSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A revocation summary. Its code is unique within a tenant.
    final class RevocationSummary {
        var code: String
        var title: String
        var visitMinutes: Int
        var updatedAt: Int
        var copay: Double
        var reviewer: String
        var cost: Double
        var archived: Bool
        var visible: Bool
        var status: RevocationSummaryStatus

        init(code: String, title: String, visitMinutes: Int, updatedAt: Int, copay: Double, reviewer: String, cost: Double, archived: Bool, visible: Bool, status: RevocationSummaryStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.updatedAt = updatedAt
            self.copay = copay
            self.reviewer = reviewer
            self.cost = cost
            self.archived = archived
            self.visible = visible
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

        func canMoveTo(_ next: RevocationSummaryStatus) -> Bool {
            switch status {
            case .new:
                return next == RevocationSummaryStatus.done
            case .queued:
                return next == RevocationSummaryStatus.running || next == RevocationSummaryStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RevocationSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netValue() -> Double {
            return ((cost + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationSummary {
            return RevocationSummary(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                updatedAt: updatedAt,
                copay: copay,
                reviewer: reviewer,
                cost: cost,
                archived: archived,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a revocation summary in status new.
    static func newRevocationSummary(_ code: String, title: String) -> RevocationSummary {
        return RevocationSummary(
            code: code,
            title: title,
            visitMinutes: 0,
            updatedAt: 0,
            copay: 0.0,
            reviewer: "",
            cost: 0.0,
            archived: false,
            visible: false,
            status: RevocationSummaryStatus.new
        )
    }
}
