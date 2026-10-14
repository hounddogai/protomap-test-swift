import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff threshold is in its life cycle.
    enum HandoffThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A handoff threshold. Its code is unique within a tenant.
    final class HandoffThreshold {
        var code: String
        var title: String
        var patientRef: String
        var rate: Double
        var facility: String
        var weight: Double
        var version: Int
        var minimum: Double
        var visible: Bool
        var refills: Int
        var status: HandoffThresholdStatus

        init(code: String, title: String, patientRef: String, rate: Double, facility: String, weight: Double, version: Int, minimum: Double, visible: Bool, refills: Int, status: HandoffThresholdStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.rate = rate
            self.facility = facility
            self.weight = weight
            self.version = version
            self.minimum = minimum
            self.visible = visible
            self.refills = refills
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

        func canMoveTo(_ next: HandoffThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == HandoffThresholdStatus.inProgress || next == HandoffThresholdStatus.completed
            case .inProgress:
                return next == HandoffThresholdStatus.completed || next == HandoffThresholdStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: HandoffThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return (minimum * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> HandoffThreshold {
            return HandoffThreshold(
                code: code,
                title: title,
                patientRef: patientRef,
                rate: rate,
                facility: facility,
                weight: weight,
                version: version,
                minimum: minimum,
                visible: visible,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a handoff threshold in status planned.
    static func newHandoffThreshold(_ code: String, title: String) -> HandoffThreshold {
        return HandoffThreshold(
            code: code,
            title: title,
            patientRef: "",
            rate: 0.0,
            facility: "",
            weight: 0.0,
            version: 0,
            minimum: 0.0,
            visible: false,
            refills: 0,
            status: HandoffThresholdStatus.planned
        )
    }
}
