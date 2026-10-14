import AcmePlatform
import Foundation

extension Labs {
    /// Where a global reference range segment is in its life cycle.
    enum GlobalReferenceRangeSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A global reference range segment as the reference range team keeps it.
    final class GlobalReferenceRangeSegment {
        var code: String
        var label: String
        var specialty: String
        var externalRef: String
        var channel: String
        var discount: Double
        var category: String
        var patientRef: String
        var procedureCode: String
        var status: GlobalReferenceRangeSegmentStatus

        init(code: String, label: String, specialty: String, externalRef: String, channel: String, discount: Double, category: String, patientRef: String, procedureCode: String, status: GlobalReferenceRangeSegmentStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.externalRef = externalRef
            self.channel = channel
            self.discount = discount
            self.category = category
            self.patientRef = patientRef
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: GlobalReferenceRangeSegmentStatus) -> Bool {
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
                return next == GlobalReferenceRangeSegmentStatus.ready || next == GlobalReferenceRangeSegmentStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == GlobalReferenceRangeSegmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalReferenceRangeSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global reference range segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global reference range segment") \(code)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> GlobalReferenceRangeSegment {
            return GlobalReferenceRangeSegment(
                code: code,
                label: label,
                specialty: specialty,
                externalRef: externalRef,
                channel: channel,
                discount: discount,
                category: category,
                patientRef: patientRef,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global reference range segment in status idle.
    static func newGlobalReferenceRangeSegment(_ code: String, label: String) -> GlobalReferenceRangeSegment {
        return GlobalReferenceRangeSegment(
            code: code,
            label: label,
            specialty: "",
            externalRef: "",
            channel: "",
            discount: 0.0,
            category: "",
            patientRef: "",
            procedureCode: "",
            status: GlobalReferenceRangeSegmentStatus.idle
        )
    }
}
