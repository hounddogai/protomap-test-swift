import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal accession segment is in its life cycle.
    enum SeasonalAccessionSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A seasonal accession segment. Its code is unique within a tenant.
    final class SeasonalAccessionSegment {
        var code: String
        var label: String
        var batchSize: Int
        var createdAt: Int
        var reviewer: String
        var approved: Bool
        var rate: Double
        var status: SeasonalAccessionSegmentStatus

        init(code: String, label: String, batchSize: Int, createdAt: Int, reviewer: String, approved: Bool, rate: Double, status: SeasonalAccessionSegmentStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.createdAt = createdAt
            self.reviewer = reviewer
            self.approved = approved
            self.rate = rate
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

        func canMoveTo(_ next: SeasonalAccessionSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SeasonalAccessionSegmentStatus.suspended || next == SeasonalAccessionSegmentStatus.closed
            case .suspended:
                return next == SeasonalAccessionSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalAccessionSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal accession segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return (Double(createdAt) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalAccessionSegment {
            return SeasonalAccessionSegment(
                code: code,
                label: label,
                batchSize: batchSize,
                createdAt: createdAt,
                reviewer: reviewer,
                approved: approved,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal accession segment in status draft.
    static func newSeasonalAccessionSegment(_ code: String, label: String) -> SeasonalAccessionSegment {
        return SeasonalAccessionSegment(
            code: code,
            label: label,
            batchSize: 0,
            createdAt: 0,
            reviewer: "",
            approved: false,
            rate: 0.0,
            status: SeasonalAccessionSegmentStatus.draft
        )
    }
}
