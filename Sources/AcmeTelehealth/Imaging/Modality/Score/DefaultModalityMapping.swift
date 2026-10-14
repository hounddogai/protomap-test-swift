import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default modality mapping is in its life cycle.
    enum DefaultModalityMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default modality mapping. Its code is unique within a tenant.
    final class DefaultModalityMapping {
        var code: String
        var title: String
        var version: Int
        var channel: String
        var rate: Double
        var discount: Double
        var status: DefaultModalityMappingStatus

        init(code: String, title: String, version: Int, channel: String, rate: Double, discount: Double, status: DefaultModalityMappingStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.channel = channel
            self.rate = rate
            self.discount = discount
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

        func canMoveTo(_ next: DefaultModalityMappingStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DefaultModalityMappingStatus.draining
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

        func moveTo(_ next: DefaultModalityMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default modality mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveTotal() -> Double {
            return ((discount + rate) * 100).rounded() / 100
        }

        func copyValue() -> DefaultModalityMapping {
            return DefaultModalityMapping(
                code: code,
                title: title,
                version: version,
                channel: channel,
                rate: rate,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a default modality mapping in status idle.
    static func newDefaultModalityMapping(_ code: String, title: String) -> DefaultModalityMapping {
        return DefaultModalityMapping(
            code: code,
            title: title,
            version: 0,
            channel: "",
            rate: 0.0,
            discount: 0.0,
            status: DefaultModalityMappingStatus.idle
        )
    }
}
