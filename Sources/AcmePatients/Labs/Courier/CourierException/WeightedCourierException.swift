import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted courier exception is in its life cycle.
    enum WeightedCourierExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One weighted courier exception, with what the planners need to act on it.
    final class WeightedCourierException {
        var code: String
        var label: String
        var acuity: Int
        var currency: String
        var checksum: String
        var segment: String
        var patientRef: String
        var startsAt: Int
        var category: String
        var status: WeightedCourierExceptionStatus

        init(code: String, label: String, acuity: Int, currency: String, checksum: String, segment: String, patientRef: String, startsAt: Int, category: String, status: WeightedCourierExceptionStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.currency = currency
            self.checksum = checksum
            self.segment = segment
            self.patientRef = patientRef
            self.startsAt = startsAt
            self.category = category
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

        func canMoveTo(_ next: WeightedCourierExceptionStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedCourierExceptionStatus.warming || next == WeightedCourierExceptionStatus.ready
            case .warming:
                return next == WeightedCourierExceptionStatus.draining || next == WeightedCourierExceptionStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WeightedCourierExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted courier exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedVolume() -> Double {
            return ((Double(startsAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCourierException {
            return WeightedCourierException(
                code: code,
                label: label,
                acuity: acuity,
                currency: currency,
                checksum: checksum,
                segment: segment,
                patientRef: patientRef,
                startsAt: startsAt,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a weighted courier exception in status idle.
    static func newWeightedCourierException(_ code: String, label: String) -> WeightedCourierException {
        return WeightedCourierException(
            code: code,
            label: label,
            acuity: 0,
            currency: "",
            checksum: "",
            segment: "",
            patientRef: "",
            startsAt: 0,
            category: "",
            status: WeightedCourierExceptionStatus.idle
        )
    }
}
