import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality rollup is in its life cycle.
    enum ModalityRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One modality rollup, with what the planners need to act on it.
    final class ModalityRollup {
        var code: String
        var title: String
        var budget: Double
        var reviewer: String
        var bed: String
        var ward: String
        var version: Int
        var status: ModalityRollupStatus

        init(code: String, title: String, budget: Double, reviewer: String, bed: String, ward: String, version: Int, status: ModalityRollupStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.reviewer = reviewer
            self.bed = bed
            self.ward = ward
            self.version = version
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

        func canMoveTo(_ next: ModalityRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == ModalityRollupStatus.active || next == ModalityRollupStatus.closed
            case .pending:
                return next == ModalityRollupStatus.suspended
            case .active:
                return next == ModalityRollupStatus.suspended
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

        func moveTo(_ next: ModalityRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return ((budget - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityRollup {
            return ModalityRollup(
                code: code,
                title: title,
                budget: budget,
                reviewer: reviewer,
                bed: bed,
                ward: ward,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a modality rollup in status draft.
    static func newModalityRollup(_ code: String, title: String) -> ModalityRollup {
        return ModalityRollup(
            code: code,
            title: title,
            budget: 0.0,
            reviewer: "",
            bed: "",
            ward: "",
            version: 0,
            status: ModalityRollupStatus.draft
        )
    }
}
