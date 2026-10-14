import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped closure segment is in its life cycle.
    enum CappedClosureSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped closure segment. Its code is unique within a tenant.
    final class CappedClosureSegment {
        var code: String
        var name: String
        var currency: String
        var minimum: Double
        var copay: Double
        var pinned: Bool
        var diagnosisCode: String
        var version: Int
        var startsAt: Int
        var capacity: Int
        var facility: String
        var status: CappedClosureSegmentStatus

        init(code: String, name: String, currency: String, minimum: Double, copay: Double, pinned: Bool, diagnosisCode: String, version: Int, startsAt: Int, capacity: Int, facility: String, status: CappedClosureSegmentStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.minimum = minimum
            self.copay = copay
            self.pinned = pinned
            self.diagnosisCode = diagnosisCode
            self.version = version
            self.startsAt = startsAt
            self.capacity = capacity
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedClosureSegmentStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedClosureSegmentStatus.published || next == CappedClosureSegmentStatus.retired
            case .validated:
                return next == CappedClosureSegmentStatus.published
            case .published:
                return next == CappedClosureSegmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedClosureSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped closure segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("capped closure segment") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(capacity) * copay * 100).rounded() / 100
        }

        func copyValue() -> CappedClosureSegment {
            return CappedClosureSegment(
                code: code,
                name: name,
                currency: currency,
                minimum: minimum,
                copay: copay,
                pinned: pinned,
                diagnosisCode: diagnosisCode,
                version: version,
                startsAt: startsAt,
                capacity: capacity,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a capped closure segment in status created.
    static func newCappedClosureSegment(_ code: String, name: String) -> CappedClosureSegment {
        return CappedClosureSegment(
            code: code,
            name: name,
            currency: "",
            minimum: 0.0,
            copay: 0.0,
            pinned: false,
            diagnosisCode: "",
            version: 0,
            startsAt: 0,
            capacity: 0,
            facility: "",
            status: CappedClosureSegmentStatus.created
        )
    }
}
