import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy allocation is in its life cycle.
    enum ProxyAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a proxy allocation and its current status.
    final class ProxyAllocation {
        var code: String
        var name: String
        var ceiling: Double
        var channel: String
        var batchSize: Int
        var status: ProxyAllocationStatus

        init(code: String, name: String, ceiling: Double, channel: String, batchSize: Int, status: ProxyAllocationStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.channel = channel
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProxyAllocationStatus) -> Bool {
            switch status {
            case .new:
                return next == ProxyAllocationStatus.running || next == ProxyAllocationStatus.failed
            case .queued:
                return next == ProxyAllocationStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ProxyAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("proxy allocation") \(code)"
        }

        func weightedExposure() -> Double {
            return (ceiling * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> ProxyAllocation {
            return ProxyAllocation(
                code: code,
                name: name,
                ceiling: ceiling,
                channel: channel,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a proxy allocation in status new.
    static func newProxyAllocation(_ code: String, name: String) -> ProxyAllocation {
        return ProxyAllocation(
            code: code,
            name: name,
            ceiling: 0.0,
            channel: "",
            batchSize: 0,
            status: ProxyAllocationStatus.new
        )
    }
}
