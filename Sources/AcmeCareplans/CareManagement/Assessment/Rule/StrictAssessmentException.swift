import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a strict assessment exception is in its life cycle.
    enum StrictAssessmentExceptionStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a strict assessment exception and its current status.
    final class StrictAssessmentException {
        var code: String
        var label: String
        var channel: String
        var facility: String
        var updatedAt: Int
        var threshold: Double
        var floorValue: Double
        var status: StrictAssessmentExceptionStatus

        init(code: String, label: String, channel: String, facility: String, updatedAt: Int, threshold: Double, floorValue: Double, status: StrictAssessmentExceptionStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.facility = facility
            self.updatedAt = updatedAt
            self.threshold = threshold
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictAssessmentExceptionStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == StrictAssessmentExceptionStatus.resolved || next == StrictAssessmentExceptionStatus.reopened
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == StrictAssessmentExceptionStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictAssessmentExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict assessment exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return (Double(updatedAt) * threshold * 100).rounded() / 100
        }

        func copyValue() -> StrictAssessmentException {
            return StrictAssessmentException(
                code: code,
                label: label,
                channel: channel,
                facility: facility,
                updatedAt: updatedAt,
                threshold: threshold,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a strict assessment exception in status open.
    static func newStrictAssessmentException(_ code: String, label: String) -> StrictAssessmentException {
        return StrictAssessmentException(
            code: code,
            label: label,
            channel: "",
            facility: "",
            updatedAt: 0,
            threshold: 0.0,
            floorValue: 0.0,
            status: StrictAssessmentExceptionStatus.`open`
        )
    }
}
