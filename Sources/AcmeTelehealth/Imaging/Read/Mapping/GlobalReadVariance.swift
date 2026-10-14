import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global read variance is in its life cycle.
    enum GlobalReadVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global read variance as the read team keeps it.
    final class GlobalReadVariance {
        var code: String
        var label: String
        var budget: Double
        var sequence: Int
        var weight: Double
        var visitMinutes: Int
        var checksum: String
        var contactEmail: String
        var visible: Bool
        var ratio: Double
        var status: GlobalReadVarianceStatus

        init(code: String, label: String, budget: Double, sequence: Int, weight: Double, visitMinutes: Int, checksum: String, contactEmail: String, visible: Bool, ratio: Double, status: GlobalReadVarianceStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.sequence = sequence
            self.weight = weight
            self.visitMinutes = visitMinutes
            self.checksum = checksum
            self.contactEmail = contactEmail
            self.visible = visible
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalReadVarianceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == GlobalReadVarianceStatus.cancelled
            case .completed:
                return next == GlobalReadVarianceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalReadVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global read variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global read variance") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((budget - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalReadVariance {
            return GlobalReadVariance(
                code: code,
                label: label,
                budget: budget,
                sequence: sequence,
                weight: weight,
                visitMinutes: visitMinutes,
                checksum: checksum,
                contactEmail: contactEmail,
                visible: visible,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global read variance in status planned.
    static func newGlobalReadVariance(_ code: String, label: String) -> GlobalReadVariance {
        return GlobalReadVariance(
            code: code,
            label: label,
            budget: 0.0,
            sequence: 0,
            weight: 0.0,
            visitMinutes: 0,
            checksum: "",
            contactEmail: "",
            visible: false,
            ratio: 0.0,
            status: GlobalReadVarianceStatus.planned
        )
    }
}
