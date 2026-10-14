import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority notice is in its life cycle.
    enum PriorityNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A priority notice as the priority team keeps it.
    final class PriorityNotice {
        var code: String
        var title: String
        var bed: String
        var sequence: Int
        var retries: Int
        var attributes: [String: String]
        var acuity: Int
        var patientRef: String
        var status: PriorityNoticeStatus

        init(code: String, title: String, bed: String, sequence: Int, retries: Int, attributes: [String: String], acuity: Int, patientRef: String, status: PriorityNoticeStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.sequence = sequence
            self.retries = retries
            self.attributes = attributes
            self.acuity = acuity
            self.patientRef = patientRef
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

        func canMoveTo(_ next: PriorityNoticeStatus) -> Bool {
            switch status {
            case .idle:
                return next == PriorityNoticeStatus.warming || next == PriorityNoticeStatus.stopped
            case .warming:
                return next == PriorityNoticeStatus.ready
            case .ready:
                return next == PriorityNoticeStatus.stopped
            case .draining:
                return next == PriorityNoticeStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("priority notice") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedValue() -> Double {
            return ((Double(acuity) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityNotice {
            return PriorityNotice(
                code: code,
                title: title,
                bed: bed,
                sequence: sequence,
                retries: retries,
                attributes: attributes,
                acuity: acuity,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a priority notice in status idle.
    static func newPriorityNotice(_ code: String, title: String) -> PriorityNotice {
        return PriorityNotice(
            code: code,
            title: title,
            bed: "",
            sequence: 0,
            retries: 0,
            attributes: [:],
            acuity: 0,
            patientRef: "",
            status: PriorityNoticeStatus.idle
        )
    }
}
