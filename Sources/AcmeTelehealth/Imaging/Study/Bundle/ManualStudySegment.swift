import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual study segment is in its life cycle.
    enum ManualStudySegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual study segment as the study team keeps it.
    final class ManualStudySegment {
        var code: String
        var name: String
        var country: String
        var minimum: Double
        var bed: String
        var batchSize: Int
        var status: ManualStudySegmentStatus

        init(code: String, name: String, country: String, minimum: Double, bed: String, batchSize: Int, status: ManualStudySegmentStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.minimum = minimum
            self.bed = bed
            self.batchSize = batchSize
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

        func canMoveTo(_ next: ManualStudySegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == ManualStudySegmentStatus.pending || next == ManualStudySegmentStatus.active
            case .pending:
                return next == ManualStudySegmentStatus.active
            case .active:
                return next == ManualStudySegmentStatus.suspended || next == ManualStudySegmentStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ManualStudySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual study segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedExposure() -> Double {
            return ((minimum + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ManualStudySegment {
            return ManualStudySegment(
                code: code,
                name: name,
                country: country,
                minimum: minimum,
                bed: bed,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual study segment in status draft.
    static func newManualStudySegment(_ code: String, name: String) -> ManualStudySegment {
        return ManualStudySegment(
            code: code,
            name: name,
            country: "",
            minimum: 0.0,
            bed: "",
            batchSize: 0,
            status: ManualStudySegmentStatus.draft
        )
    }
}
