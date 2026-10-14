import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient read snapshot is in its life cycle.
    enum LenientReadSnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient read snapshot as the read team keeps it.
    final class LenientReadSnapshot {
        var code: String
        var title: String
        var pinned: Bool
        var locale: String
        var startsAt: Int
        var minimum: Double
        var version: Int
        var durationMinutes: Int
        var externalRef: String
        var floorValue: Double
        var ceiling: Double
        var status: LenientReadSnapshotStatus

        init(code: String, title: String, pinned: Bool, locale: String, startsAt: Int, minimum: Double, version: Int, durationMinutes: Int, externalRef: String, floorValue: Double, ceiling: Double, status: LenientReadSnapshotStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.locale = locale
            self.startsAt = startsAt
            self.minimum = minimum
            self.version = version
            self.durationMinutes = durationMinutes
            self.externalRef = externalRef
            self.floorValue = floorValue
            self.ceiling = ceiling
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

        func canMoveTo(_ next: LenientReadSnapshotStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientReadSnapshotStatus.active
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LenientReadSnapshotStatus.suspended || next == LenientReadSnapshotStatus.closed
            case .suspended:
                return next == LenientReadSnapshotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientReadSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient read snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedTotal() -> Double {
            return ((floorValue + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientReadSnapshot {
            return LenientReadSnapshot(
                code: code,
                title: title,
                pinned: pinned,
                locale: locale,
                startsAt: startsAt,
                minimum: minimum,
                version: version,
                durationMinutes: durationMinutes,
                externalRef: externalRef,
                floorValue: floorValue,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient read snapshot in status draft.
    static func newLenientReadSnapshot(_ code: String, title: String) -> LenientReadSnapshot {
        return LenientReadSnapshot(
            code: code,
            title: title,
            pinned: false,
            locale: "",
            startsAt: 0,
            minimum: 0.0,
            version: 0,
            durationMinutes: 0,
            externalRef: "",
            floorValue: 0.0,
            ceiling: 0.0,
            status: LenientReadSnapshotStatus.draft
        )
    }
}
