import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy manifest is in its life cycle.
    enum ProxyManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A proxy manifest as the proxy team keeps it.
    final class ProxyManifest {
        var code: String
        var name: String
        var score: Double
        var acuity: Int
        var batchSize: Int
        var timezone: String
        var budget: Double
        var revision: Int
        var tags: [String]
        var status: ProxyManifestStatus

        init(code: String, name: String, score: Double, acuity: Int, batchSize: Int, timezone: String, budget: Double, revision: Int, tags: [String], status: ProxyManifestStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.acuity = acuity
            self.batchSize = batchSize
            self.timezone = timezone
            self.budget = budget
            self.revision = revision
            self.tags = tags
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

        func canMoveTo(_ next: ProxyManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ProxyManifestStatus.stopped
            case .draining:
                return next == ProxyManifestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((budget - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyManifest {
            return ProxyManifest(
                code: code,
                name: name,
                score: score,
                acuity: acuity,
                batchSize: batchSize,
                timezone: timezone,
                budget: budget,
                revision: revision,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a proxy manifest in status idle.
    static func newProxyManifest(_ code: String, name: String) -> ProxyManifest {
        return ProxyManifest(
            code: code,
            name: name,
            score: 0.0,
            acuity: 0,
            batchSize: 0,
            timezone: "",
            budget: 0.0,
            revision: 0,
            tags: [],
            status: ProxyManifestStatus.idle
        )
    }
}
