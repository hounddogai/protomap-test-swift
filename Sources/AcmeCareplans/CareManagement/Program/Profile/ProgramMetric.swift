import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program metric is in its life cycle.
    enum ProgramMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A program metric. Its code is unique within a tenant.
    final class ProgramMetric {
        var code: String
        var title: String
        var discount: Double
        var patientRef: String
        var ratio: Double
        var attempts: Int
        var locale: String
        var status: ProgramMetricStatus

        init(code: String, title: String, discount: Double, patientRef: String, ratio: Double, attempts: Int, locale: String, status: ProgramMetricStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.patientRef = patientRef
            self.ratio = ratio
            self.attempts = attempts
            self.locale = locale
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

        func canMoveTo(_ next: ProgramMetricStatus) -> Bool {
            switch status {
            case .idle:
                return next == ProgramMetricStatus.warming || next == ProgramMetricStatus.ready
            case .warming:
                return next == ProgramMetricStatus.ready
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ProgramMetricStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("program metric") \(code)"
        }

        func weightedExposure() -> Double {
            return ((discount + ratio) * 100).rounded() / 100
        }

        func copyValue() -> ProgramMetric {
            return ProgramMetric(
                code: code,
                title: title,
                discount: discount,
                patientRef: patientRef,
                ratio: ratio,
                attempts: attempts,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a program metric in status idle.
    static func newProgramMetric(_ code: String, title: String) -> ProgramMetric {
        return ProgramMetric(
            code: code,
            title: title,
            discount: 0.0,
            patientRef: "",
            ratio: 0.0,
            attempts: 0,
            locale: "",
            status: ProgramMetricStatus.idle
        )
    }
}
