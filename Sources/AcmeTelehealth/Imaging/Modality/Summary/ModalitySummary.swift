import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality summary is in its life cycle.
    enum ModalitySummaryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A modality summary. Its code is unique within a tenant.
    final class ModalitySummary {
        var code: String
        var label: String
        var refills: Int
        var pinned: Bool
        var batchSize: Int
        var unit: String
        var retries: Int
        var graceDays: Int
        var startsAt: Int
        var checksum: String
        var status: ModalitySummaryStatus

        init(code: String, label: String, refills: Int, pinned: Bool, batchSize: Int, unit: String, retries: Int, graceDays: Int, startsAt: Int, checksum: String, status: ModalitySummaryStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.pinned = pinned
            self.batchSize = batchSize
            self.unit = unit
            self.retries = retries
            self.graceDays = graceDays
            self.startsAt = startsAt
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalitySummaryStatus) -> Bool {
            switch status {
            case .planned:
                return next == ModalitySummaryStatus.scheduled || next == ModalitySummaryStatus.cancelled
            case .scheduled:
                return next == ModalitySummaryStatus.inProgress || next == ModalitySummaryStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ModalitySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedVolume() -> Double {
            return ((Double(retries) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ModalitySummary {
            return ModalitySummary(
                code: code,
                label: label,
                refills: refills,
                pinned: pinned,
                batchSize: batchSize,
                unit: unit,
                retries: retries,
                graceDays: graceDays,
                startsAt: startsAt,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a modality summary in status planned.
    static func newModalitySummary(_ code: String, label: String) -> ModalitySummary {
        return ModalitySummary(
            code: code,
            label: label,
            refills: 0,
            pinned: false,
            batchSize: 0,
            unit: "",
            retries: 0,
            graceDays: 0,
            startsAt: 0,
            checksum: "",
            status: ModalitySummaryStatus.planned
        )
    }
}
