import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback disclosure segment is in its life cycle.
    enum FallbackDisclosureSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One fallback disclosure segment, with what the planners need to act on it.
    final class FallbackDisclosureSegment {
        var code: String
        var name: String
        var limit: Int
        var maximum: Double
        var visitMinutes: Int
        var diagnosisCode: String
        var sequence: Int
        var rate: Double
        var status: FallbackDisclosureSegmentStatus

        init(code: String, name: String, limit: Int, maximum: Double, visitMinutes: Int, diagnosisCode: String, sequence: Int, rate: Double, status: FallbackDisclosureSegmentStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.maximum = maximum
            self.visitMinutes = visitMinutes
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
            self.rate = rate
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

        func canMoveTo(_ next: FallbackDisclosureSegmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackDisclosureSegmentStatus.ready
            case .warming:
                return next == FallbackDisclosureSegmentStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: FallbackDisclosureSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback disclosure segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return ((Double(visitMinutes) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> FallbackDisclosureSegment {
            return FallbackDisclosureSegment(
                code: code,
                name: name,
                limit: limit,
                maximum: maximum,
                visitMinutes: visitMinutes,
                diagnosisCode: diagnosisCode,
                sequence: sequence,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback disclosure segment in status idle.
    static func newFallbackDisclosureSegment(_ code: String, name: String) -> FallbackDisclosureSegment {
        return FallbackDisclosureSegment(
            code: code,
            name: name,
            limit: 0,
            maximum: 0.0,
            visitMinutes: 0,
            diagnosisCode: "",
            sequence: 0,
            rate: 0.0,
            status: FallbackDisclosureSegmentStatus.idle
        )
    }
}
