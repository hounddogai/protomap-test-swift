import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient assessment threshold is in its life cycle.
    enum LenientAssessmentThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient assessment threshold as the assessment team keeps it.
    final class LenientAssessmentThreshold {
        var code: String
        var name: String
        var acuity: Int
        var specialty: String
        var ceiling: Double
        var durationMinutes: Int
        var version: Int
        var ratio: Double
        var status: LenientAssessmentThresholdStatus

        init(code: String, name: String, acuity: Int, specialty: String, ceiling: Double, durationMinutes: Int, version: Int, ratio: Double, status: LenientAssessmentThresholdStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.specialty = specialty
            self.ceiling = ceiling
            self.durationMinutes = durationMinutes
            self.version = version
            self.ratio = ratio
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

        func canMoveTo(_ next: LenientAssessmentThresholdStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LenientAssessmentThresholdStatus.ready
            case .ready:
                return next == LenientAssessmentThresholdStatus.stopped
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

        func moveTo(_ next: LenientAssessmentThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient assessment threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("lenient assessment threshold") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((ceiling - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LenientAssessmentThreshold {
            return LenientAssessmentThreshold(
                code: code,
                name: name,
                acuity: acuity,
                specialty: specialty,
                ceiling: ceiling,
                durationMinutes: durationMinutes,
                version: version,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient assessment threshold in status idle.
    static func newLenientAssessmentThreshold(_ code: String, name: String) -> LenientAssessmentThreshold {
        return LenientAssessmentThreshold(
            code: code,
            name: name,
            acuity: 0,
            specialty: "",
            ceiling: 0.0,
            durationMinutes: 0,
            version: 0,
            ratio: 0.0,
            status: LenientAssessmentThresholdStatus.idle
        )
    }
}
