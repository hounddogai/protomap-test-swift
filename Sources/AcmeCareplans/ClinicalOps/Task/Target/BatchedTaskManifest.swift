import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched task manifest is in its life cycle.
    enum BatchedTaskManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a batched task manifest and its current status.
    final class BatchedTaskManifest {
        var code: String
        var name: String
        var visible: Bool
        var version: Int
        var acuity: Int
        var attributes: [String: String]
        var windowDays: Int
        var status: BatchedTaskManifestStatus

        init(code: String, name: String, visible: Bool, version: Int, acuity: Int, attributes: [String: String], windowDays: Int, status: BatchedTaskManifestStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.version = version
            self.acuity = acuity
            self.attributes = attributes
            self.windowDays = windowDays
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

        func canMoveTo(_ next: BatchedTaskManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == BatchedTaskManifestStatus.draining
            case .ready:
                return next == BatchedTaskManifestStatus.stopped
            case .draining:
                return next == BatchedTaskManifestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedTaskManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched task manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedLoad() -> Double {
            return ((Double(windowDays) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedTaskManifest {
            return BatchedTaskManifest(
                code: code,
                name: name,
                visible: visible,
                version: version,
                acuity: acuity,
                attributes: attributes,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched task manifest in status idle.
    static func newBatchedTaskManifest(_ code: String, name: String) -> BatchedTaskManifest {
        return BatchedTaskManifest(
            code: code,
            name: name,
            visible: false,
            version: 0,
            acuity: 0,
            attributes: [:],
            windowDays: 0,
            status: BatchedTaskManifestStatus.idle
        )
    }
}
