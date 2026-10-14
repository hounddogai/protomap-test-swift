import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy formulary snapshot is in its life cycle.
    enum LegacyFormularySnapshotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A legacy formulary snapshot. Its code is unique within a tenant.
    final class LegacyFormularySnapshot {
        var code: String
        var title: String
        var source: String
        var summary: String
        var weight: Double
        var name: String
        var status: LegacyFormularySnapshotStatus

        init(code: String, title: String, source: String, summary: String, weight: Double, name: String, status: LegacyFormularySnapshotStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.summary = summary
            self.weight = weight
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyFormularySnapshotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LegacyFormularySnapshotStatus.draining
            case .ready:
                return next == LegacyFormularySnapshotStatus.draining || next == LegacyFormularySnapshotStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LegacyFormularySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy formulary snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy formulary snapshot") \(code)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> LegacyFormularySnapshot {
            return LegacyFormularySnapshot(
                code: code,
                title: title,
                source: source,
                summary: summary,
                weight: weight,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a legacy formulary snapshot in status idle.
    static func newLegacyFormularySnapshot(_ code: String, title: String) -> LegacyFormularySnapshot {
        return LegacyFormularySnapshot(
            code: code,
            title: title,
            source: "",
            summary: "",
            weight: 0.0,
            name: "",
            status: LegacyFormularySnapshotStatus.idle
        )
    }
}
