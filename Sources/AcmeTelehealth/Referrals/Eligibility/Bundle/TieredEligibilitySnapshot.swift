import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered eligibility snapshot is in its life cycle.
    enum TieredEligibilitySnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered eligibility snapshot. Its code is unique within a tenant.
    final class TieredEligibilitySnapshot {
        var code: String
        var title: String
        var checksum: String
        var durationMinutes: Int
        var contactEmail: String
        var ratio: Double
        var source: String
        var status: TieredEligibilitySnapshotStatus

        init(code: String, title: String, checksum: String, durationMinutes: Int, contactEmail: String, ratio: Double, source: String, status: TieredEligibilitySnapshotStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.durationMinutes = durationMinutes
            self.contactEmail = contactEmail
            self.ratio = ratio
            self.source = source
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

        func canMoveTo(_ next: TieredEligibilitySnapshotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TieredEligibilitySnapshotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredEligibilitySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered eligibility snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedTotal() -> Double {
            return ((ratio - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredEligibilitySnapshot {
            return TieredEligibilitySnapshot(
                code: code,
                title: title,
                checksum: checksum,
                durationMinutes: durationMinutes,
                contactEmail: contactEmail,
                ratio: ratio,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered eligibility snapshot in status new.
    static func newTieredEligibilitySnapshot(_ code: String, title: String) -> TieredEligibilitySnapshot {
        return TieredEligibilitySnapshot(
            code: code,
            title: title,
            checksum: "",
            durationMinutes: 0,
            contactEmail: "",
            ratio: 0.0,
            source: "",
            status: TieredEligibilitySnapshotStatus.new
        )
    }
}
