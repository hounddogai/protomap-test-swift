import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool entry is in its life cycle.
    enum FloatPoolEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A float pool entry as the float pool team keeps it.
    final class FloatPoolEntry {
        var code: String
        var name: String
        var region: String
        var windowDays: Int
        var threshold: Double
        var margin: Double
        var summary: String
        var score: Double
        var status: FloatPoolEntryStatus

        init(code: String, name: String, region: String, windowDays: Int, threshold: Double, margin: Double, summary: String, score: Double, status: FloatPoolEntryStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.windowDays = windowDays
            self.threshold = threshold
            self.margin = margin
            self.summary = summary
            self.score = score
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

        func canMoveTo(_ next: FloatPoolEntryStatus) -> Bool {
            switch status {
            case .requested:
                return next == FloatPoolEntryStatus.granted || next == FloatPoolEntryStatus.revoked
            case .granted:
                return next == FloatPoolEntryStatus.revoked
            case .revoked:
                return next == FloatPoolEntryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("float pool entry") \(code)"
        }

        func netVolume() -> Double {
            return ((margin - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolEntry {
            return FloatPoolEntry(
                code: code,
                name: name,
                region: region,
                windowDays: windowDays,
                threshold: threshold,
                margin: margin,
                summary: summary,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a float pool entry in status requested.
    static func newFloatPoolEntry(_ code: String, name: String) -> FloatPoolEntry {
        return FloatPoolEntry(
            code: code,
            name: name,
            region: "",
            windowDays: 0,
            threshold: 0.0,
            margin: 0.0,
            summary: "",
            score: 0.0,
            status: FloatPoolEntryStatus.requested
        )
    }
}
