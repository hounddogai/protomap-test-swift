import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal assessment snapshot is in its life cycle.
    enum SeasonalAssessmentSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal assessment snapshot as the assessment team keeps it.
    final class SeasonalAssessmentSnapshot {
        var code: String
        var title: String
        var graceDays: Int
        var rate: Double
        var batchSize: Int
        var capacity: Int
        var category: String
        var ceiling: Double
        var status: SeasonalAssessmentSnapshotStatus

        init(code: String, title: String, graceDays: Int, rate: Double, batchSize: Int, capacity: Int, category: String, ceiling: Double, status: SeasonalAssessmentSnapshotStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.rate = rate
            self.batchSize = batchSize
            self.capacity = capacity
            self.category = category
            self.ceiling = ceiling
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

        func canMoveTo(_ next: SeasonalAssessmentSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                return next == SeasonalAssessmentSnapshotStatus.revoked || next == SeasonalAssessmentSnapshotStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SeasonalAssessmentSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal assessment snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedVolume() -> Double {
            return (rate * ceiling * 100).rounded() / 100
        }

        func copyValue() -> SeasonalAssessmentSnapshot {
            return SeasonalAssessmentSnapshot(
                code: code,
                title: title,
                graceDays: graceDays,
                rate: rate,
                batchSize: batchSize,
                capacity: capacity,
                category: category,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a seasonal assessment snapshot in status requested.
    static func newSeasonalAssessmentSnapshot(_ code: String, title: String) -> SeasonalAssessmentSnapshot {
        return SeasonalAssessmentSnapshot(
            code: code,
            title: title,
            graceDays: 0,
            rate: 0.0,
            batchSize: 0,
            capacity: 0,
            category: "",
            ceiling: 0.0,
            status: SeasonalAssessmentSnapshotStatus.requested
        )
    }
}
