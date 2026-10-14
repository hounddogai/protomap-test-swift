import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read variance is in its life cycle.
    enum ReadVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One read variance, with what the planners need to act on it.
    final class ReadVariance {
        var code: String
        var name: String
        var segment: String
        var visitMinutes: Int
        var ratio: Double
        var status: ReadVarianceStatus

        init(code: String, name: String, segment: String, visitMinutes: Int, ratio: Double, status: ReadVarianceStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.visitMinutes = visitMinutes
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReadVarianceStatus) -> Bool {
            switch status {
            case .created:
                return next == ReadVarianceStatus.published || next == ReadVarianceStatus.retired
            case .validated:
                return next == ReadVarianceStatus.retired
            case .published:
                return next == ReadVarianceStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedValue() -> Double {
            return ((Double(visitMinutes) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> ReadVariance {
            return ReadVariance(
                code: code,
                name: name,
                segment: segment,
                visitMinutes: visitMinutes,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a read variance in status created.
    static func newReadVariance(_ code: String, name: String) -> ReadVariance {
        return ReadVariance(
            code: code,
            name: name,
            segment: "",
            visitMinutes: 0,
            ratio: 0.0,
            status: ReadVarianceStatus.created
        )
    }
}
