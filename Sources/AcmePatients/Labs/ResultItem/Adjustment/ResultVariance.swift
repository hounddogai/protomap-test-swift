import AcmePlatform
import Foundation

extension Labs {
    /// Where a result variance is in its life cycle.
    enum ResultVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A result variance. Its code is unique within a tenant.
    final class ResultVariance {
        var code: String
        var title: String
        var batchSize: Int
        var source: String
        var limit: Int
        var status: ResultVarianceStatus

        init(code: String, title: String, batchSize: Int, source: String, limit: Int, status: ResultVarianceStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.source = source
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultVarianceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ResultVarianceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netExposure() -> Double {
            return ((Double(limit) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ResultVariance {
            return ResultVariance(
                code: code,
                title: title,
                batchSize: batchSize,
                source: source,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a result variance in status requested.
    static func newResultVariance(_ code: String, title: String) -> ResultVariance {
        return ResultVariance(
            code: code,
            title: title,
            batchSize: 0,
            source: "",
            limit: 0,
            status: ResultVarianceStatus.requested
        )
    }
}
