import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual recall group is in its life cycle.
    enum ManualRecallGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A manual recall group as the recall team keeps it.
    final class ManualRecallGroup {
        var code: String
        var name: String
        var label: String
        var maximum: Double
        var segment: String
        var startsAt: Int
        var acuity: Int
        var attempts: Int
        var weight: Double
        var procedureCode: String
        var bed: String
        var status: ManualRecallGroupStatus

        init(code: String, name: String, label: String, maximum: Double, segment: String, startsAt: Int, acuity: Int, attempts: Int, weight: Double, procedureCode: String, bed: String, status: ManualRecallGroupStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.maximum = maximum
            self.segment = segment
            self.startsAt = startsAt
            self.acuity = acuity
            self.attempts = attempts
            self.weight = weight
            self.procedureCode = procedureCode
            self.bed = bed
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

        func canMoveTo(_ next: ManualRecallGroupStatus) -> Bool {
            switch status {
            case .idle:
                return next == ManualRecallGroupStatus.ready || next == ManualRecallGroupStatus.stopped
            case .warming:
                return next == ManualRecallGroupStatus.ready || next == ManualRecallGroupStatus.stopped
            case .ready:
                return next == ManualRecallGroupStatus.draining || next == ManualRecallGroupStatus.stopped
            case .draining:
                return next == ManualRecallGroupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualRecallGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual recall group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func netValue() -> Double {
            return ((Double(attempts) - weight) * 100).rounded() / 100
        }

        func copyValue() -> ManualRecallGroup {
            return ManualRecallGroup(
                code: code,
                name: name,
                label: label,
                maximum: maximum,
                segment: segment,
                startsAt: startsAt,
                acuity: acuity,
                attempts: attempts,
                weight: weight,
                procedureCode: procedureCode,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual recall group in status idle.
    static func newManualRecallGroup(_ code: String, name: String) -> ManualRecallGroup {
        return ManualRecallGroup(
            code: code,
            name: name,
            label: "",
            maximum: 0.0,
            segment: "",
            startsAt: 0,
            acuity: 0,
            attempts: 0,
            weight: 0.0,
            procedureCode: "",
            bed: "",
            status: ManualRecallGroupStatus.idle
        )
    }
}
