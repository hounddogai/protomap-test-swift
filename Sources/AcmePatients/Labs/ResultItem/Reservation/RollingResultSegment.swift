import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling result segment is in its life cycle.
    enum RollingResultSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling result segment. Its code is unique within a tenant.
    final class RollingResultSegment {
        var code: String
        var label: String
        var batchSize: Int
        var score: Double
        var locale: String
        var summary: String
        var status: RollingResultSegmentStatus

        init(code: String, label: String, batchSize: Int, score: Double, locale: String, summary: String, status: RollingResultSegmentStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.score = score
            self.locale = locale
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingResultSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RollingResultSegmentStatus.suspended || next == RollingResultSegmentStatus.closed
            case .suspended:
                return next == RollingResultSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingResultSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling result segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netTotal() -> Double {
            return ((Double(batchSize) - score) * 100).rounded() / 100
        }

        func copyValue() -> RollingResultSegment {
            return RollingResultSegment(
                code: code,
                label: label,
                batchSize: batchSize,
                score: score,
                locale: locale,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling result segment in status draft.
    static func newRollingResultSegment(_ code: String, label: String) -> RollingResultSegment {
        return RollingResultSegment(
            code: code,
            label: label,
            batchSize: 0,
            score: 0.0,
            locale: "",
            summary: "",
            status: RollingResultSegmentStatus.draft
        )
    }
}
