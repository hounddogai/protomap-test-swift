import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy rollup is in its life cycle.
    enum ProxyRollupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a proxy rollup and its current status.
    final class ProxyRollup {
        var code: String
        var name: String
        var title: String
        var revision: Int
        var quantity: Int
        var version: Int
        var facility: String
        var threshold: Double
        var status: ProxyRollupStatus

        init(code: String, name: String, title: String, revision: Int, quantity: Int, version: Int, facility: String, threshold: Double, status: ProxyRollupStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.revision = revision
            self.quantity = quantity
            self.version = version
            self.facility = facility
            self.threshold = threshold
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

        func canMoveTo(_ next: ProxyRollupStatus) -> Bool {
            switch status {
            case .created:
                return next == ProxyRollupStatus.published
            case .validated:
                return next == ProxyRollupStatus.published || next == ProxyRollupStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ProxyRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedLoad() -> Double {
            return (threshold * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> ProxyRollup {
            return ProxyRollup(
                code: code,
                name: name,
                title: title,
                revision: revision,
                quantity: quantity,
                version: version,
                facility: facility,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a proxy rollup in status created.
    static func newProxyRollup(_ code: String, name: String) -> ProxyRollup {
        return ProxyRollup(
            code: code,
            name: name,
            title: "",
            revision: 0,
            quantity: 0,
            version: 0,
            facility: "",
            threshold: 0.0,
            status: ProxyRollupStatus.created
        )
    }
}
