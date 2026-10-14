import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient order set snapshot is in its life cycle.
    enum LenientOrderSetSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a lenient order set snapshot and its current status.
    final class LenientOrderSetSnapshot {
        var code: String
        var label: String
        var attempts: Int
        var retries: Int
        var segment: String
        var endsAt: Int
        var externalRef: String
        var cost: Double
        var ward: String
        var title: String
        var status: LenientOrderSetSnapshotStatus

        init(code: String, label: String, attempts: Int, retries: Int, segment: String, endsAt: Int, externalRef: String, cost: Double, ward: String, title: String, status: LenientOrderSetSnapshotStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.retries = retries
            self.segment = segment
            self.endsAt = endsAt
            self.externalRef = externalRef
            self.cost = cost
            self.ward = ward
            self.title = title
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

        func canMoveTo(_ next: LenientOrderSetSnapshotStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientOrderSetSnapshotStatus.failed
            case .queued:
                return next == LenientOrderSetSnapshotStatus.running || next == LenientOrderSetSnapshotStatus.done
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: LenientOrderSetSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient order set snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("lenient order set snapshot") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(endsAt) + cost) * 100).rounded() / 100
        }

        func copyValue() -> LenientOrderSetSnapshot {
            return LenientOrderSetSnapshot(
                code: code,
                label: label,
                attempts: attempts,
                retries: retries,
                segment: segment,
                endsAt: endsAt,
                externalRef: externalRef,
                cost: cost,
                ward: ward,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a lenient order set snapshot in status new.
    static func newLenientOrderSetSnapshot(_ code: String, label: String) -> LenientOrderSetSnapshot {
        return LenientOrderSetSnapshot(
            code: code,
            label: label,
            attempts: 0,
            retries: 0,
            segment: "",
            endsAt: 0,
            externalRef: "",
            cost: 0.0,
            ward: "",
            title: "",
            status: LenientOrderSetSnapshotStatus.new
        )
    }
}
