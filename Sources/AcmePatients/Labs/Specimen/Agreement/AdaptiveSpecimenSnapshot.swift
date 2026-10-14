import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive specimen snapshot is in its life cycle.
    enum AdaptiveSpecimenSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One adaptive specimen snapshot, with what the planners need to act on it.
    final class AdaptiveSpecimenSnapshot {
        var code: String
        var title: String
        var ward: String
        var durationMinutes: Int
        var unit: String
        var status: AdaptiveSpecimenSnapshotStatus

        init(code: String, title: String, ward: String, durationMinutes: Int, unit: String, status: AdaptiveSpecimenSnapshotStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.durationMinutes = durationMinutes
            self.unit = unit
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

        func canMoveTo(_ next: AdaptiveSpecimenSnapshotStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveSpecimenSnapshotStatus.queued
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AdaptiveSpecimenSnapshotStatus.failed
            case .done:
                return next == AdaptiveSpecimenSnapshotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveSpecimenSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive specimen snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive specimen snapshot") \(code)"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> AdaptiveSpecimenSnapshot {
            return AdaptiveSpecimenSnapshot(
                code: code,
                title: title,
                ward: ward,
                durationMinutes: durationMinutes,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a adaptive specimen snapshot in status new.
    static func newAdaptiveSpecimenSnapshot(_ code: String, title: String) -> AdaptiveSpecimenSnapshot {
        return AdaptiveSpecimenSnapshot(
            code: code,
            title: title,
            ward: "",
            durationMinutes: 0,
            unit: "",
            status: AdaptiveSpecimenSnapshotStatus.new
        )
    }
}
