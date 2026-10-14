import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial segment is in its life cycle.
    enum DenialSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a denial segment and its current status.
    final class DenialSegment {
        var code: String
        var title: String
        var summary: String
        var batchSize: Int
        var procedureCode: String
        var maximum: Double
        var active: Bool
        var refills: Int
        var locale: String
        var cost: Double
        var expiresAt: Int
        var status: DenialSegmentStatus

        init(code: String, title: String, summary: String, batchSize: Int, procedureCode: String, maximum: Double, active: Bool, refills: Int, locale: String, cost: Double, expiresAt: Int, status: DenialSegmentStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.batchSize = batchSize
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.active = active
            self.refills = refills
            self.locale = locale
            self.cost = cost
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: DenialSegmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == DenialSegmentStatus.warming
            case .warming:
                return next == DenialSegmentStatus.draining || next == DenialSegmentStatus.stopped
            case .ready:
                return next == DenialSegmentStatus.stopped
            case .draining:
                return next == DenialSegmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveVolume() -> Double {
            return (maximum * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> DenialSegment {
            return DenialSegment(
                code: code,
                title: title,
                summary: summary,
                batchSize: batchSize,
                procedureCode: procedureCode,
                maximum: maximum,
                active: active,
                refills: refills,
                locale: locale,
                cost: cost,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a denial segment in status idle.
    static func newDenialSegment(_ code: String, title: String) -> DenialSegment {
        return DenialSegment(
            code: code,
            title: title,
            summary: "",
            batchSize: 0,
            procedureCode: "",
            maximum: 0.0,
            active: false,
            refills: 0,
            locale: "",
            cost: 0.0,
            expiresAt: 0,
            status: DenialSegmentStatus.idle
        )
    }
}
