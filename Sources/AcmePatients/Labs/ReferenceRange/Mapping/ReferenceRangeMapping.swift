import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range mapping is in its life cycle.
    enum ReferenceRangeMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A reference range mapping as the reference range team keeps it.
    final class ReferenceRangeMapping {
        var code: String
        var name: String
        var visitMinutes: Int
        var ratio: Double
        var retries: Int
        var status: ReferenceRangeMappingStatus

        init(code: String, name: String, visitMinutes: Int, ratio: Double, retries: Int, status: ReferenceRangeMappingStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.ratio = ratio
            self.retries = retries
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

        func canMoveTo(_ next: ReferenceRangeMappingStatus) -> Bool {
            switch status {
            case .idle:
                return next == ReferenceRangeMappingStatus.draining || next == ReferenceRangeMappingStatus.stopped
            case .warming:
                return next == ReferenceRangeMappingStatus.draining || next == ReferenceRangeMappingStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ReferenceRangeMappingStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveVolume() -> Double {
            return (ratio * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeMapping {
            return ReferenceRangeMapping(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                ratio: ratio,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a reference range mapping in status idle.
    static func newReferenceRangeMapping(_ code: String, name: String) -> ReferenceRangeMapping {
        return ReferenceRangeMapping(
            code: code,
            name: name,
            visitMinutes: 0,
            ratio: 0.0,
            retries: 0,
            status: ReferenceRangeMappingStatus.idle
        )
    }
}
