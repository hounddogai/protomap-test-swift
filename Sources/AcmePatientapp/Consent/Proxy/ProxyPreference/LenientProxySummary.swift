import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient proxy summary is in its life cycle.
    enum LenientProxySummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient proxy summary as the proxy team keeps it.
    final class LenientProxySummary {
        var code: String
        var name: String
        var encounterID: String
        var checksum: String
        var minimum: Double
        var maximum: Double
        var revision: Int
        var batchSize: Int
        var version: Int
        var refills: Int
        var ceiling: Double
        var status: LenientProxySummaryStatus

        init(code: String, name: String, encounterID: String, checksum: String, minimum: Double, maximum: Double, revision: Int, batchSize: Int, version: Int, refills: Int, ceiling: Double, status: LenientProxySummaryStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.checksum = checksum
            self.minimum = minimum
            self.maximum = maximum
            self.revision = revision
            self.batchSize = batchSize
            self.version = version
            self.refills = refills
            self.ceiling = ceiling
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

        func canMoveTo(_ next: LenientProxySummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientProxySummaryStatus.granted || next == LenientProxySummaryStatus.revoked
            case .granted:
                return next == LenientProxySummaryStatus.revoked || next == LenientProxySummaryStatus.expired
            case .revoked:
                return next == LenientProxySummaryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientProxySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient proxy summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("lenient proxy summary") \(code)"
        }

        func netValue() -> Double {
            return ((Double(batchSize) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> LenientProxySummary {
            return LenientProxySummary(
                code: code,
                name: name,
                encounterID: encounterID,
                checksum: checksum,
                minimum: minimum,
                maximum: maximum,
                revision: revision,
                batchSize: batchSize,
                version: version,
                refills: refills,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient proxy summary in status requested.
    static func newLenientProxySummary(_ code: String, name: String) -> LenientProxySummary {
        return LenientProxySummary(
            code: code,
            name: name,
            encounterID: "",
            checksum: "",
            minimum: 0.0,
            maximum: 0.0,
            revision: 0,
            batchSize: 0,
            version: 0,
            refills: 0,
            ceiling: 0.0,
            status: LenientProxySummaryStatus.requested
        )
    }
}
