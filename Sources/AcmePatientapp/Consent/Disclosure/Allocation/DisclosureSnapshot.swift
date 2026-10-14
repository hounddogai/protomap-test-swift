import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure snapshot is in its life cycle.
    enum DisclosureSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a disclosure snapshot and its current status.
    final class DisclosureSnapshot {
        var code: String
        var title: String
        var timezone: String
        var discount: Double
        var reviewer: String
        var externalRef: String
        var status: DisclosureSnapshotStatus

        init(code: String, title: String, timezone: String, discount: Double, reviewer: String, externalRef: String, status: DisclosureSnapshotStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.discount = discount
            self.reviewer = reviewer
            self.externalRef = externalRef
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

        func canMoveTo(_ next: DisclosureSnapshotStatus) -> Bool {
            switch status {
            case .new:
                return next == DisclosureSnapshotStatus.running || next == DisclosureSnapshotStatus.failed
            case .queued:
                return next == DisclosureSnapshotStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: DisclosureSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("disclosure snapshot") \(code)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> DisclosureSnapshot {
            return DisclosureSnapshot(
                code: code,
                title: title,
                timezone: timezone,
                discount: discount,
                reviewer: reviewer,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a disclosure snapshot in status new.
    static func newDisclosureSnapshot(_ code: String, title: String) -> DisclosureSnapshot {
        return DisclosureSnapshot(
            code: code,
            title: title,
            timezone: "",
            discount: 0.0,
            reviewer: "",
            externalRef: "",
            status: DisclosureSnapshotStatus.new
        )
    }
}
