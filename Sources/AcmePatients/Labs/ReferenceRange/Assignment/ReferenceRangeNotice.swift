import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range notice is in its life cycle.
    enum ReferenceRangeNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One reference range notice, with what the planners need to act on it.
    final class ReferenceRangeNotice {
        var code: String
        var label: String
        var limit: Int
        var unit: String
        var capacity: Int
        var allergy: String
        var patientRef: String
        var status: ReferenceRangeNoticeStatus

        init(code: String, label: String, limit: Int, unit: String, capacity: Int, allergy: String, patientRef: String, status: ReferenceRangeNoticeStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.unit = unit
            self.capacity = capacity
            self.allergy = allergy
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

        func canMoveTo(_ next: ReferenceRangeNoticeStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ReferenceRangeNoticeStatus.draining || next == ReferenceRangeNoticeStatus.stopped
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

        func moveTo(_ next: ReferenceRangeNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveLoad() -> Double {
            return ((Double(limit) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeNotice {
            return ReferenceRangeNotice(
                code: code,
                label: label,
                limit: limit,
                unit: unit,
                capacity: capacity,
                allergy: allergy,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a reference range notice in status idle.
    static func newReferenceRangeNotice(_ code: String, label: String) -> ReferenceRangeNotice {
        return ReferenceRangeNotice(
            code: code,
            label: label,
            limit: 0,
            unit: "",
            capacity: 0,
            allergy: "",
            patientRef: "",
            status: ReferenceRangeNoticeStatus.idle
        )
    }
}
