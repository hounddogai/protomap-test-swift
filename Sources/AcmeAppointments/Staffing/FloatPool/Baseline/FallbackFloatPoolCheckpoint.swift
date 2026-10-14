import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback float pool checkpoint is in its life cycle.
    enum FallbackFloatPoolCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A fallback float pool checkpoint as the float pool team keeps it.
    final class FallbackFloatPoolCheckpoint {
        var code: String
        var label: String
        var createdAt: Int
        var attempts: Int
        var minimum: Double
        var attributes: [String: String]
        var status: FallbackFloatPoolCheckpointStatus

        init(code: String, label: String, createdAt: Int, attempts: Int, minimum: Double, attributes: [String: String], status: FallbackFloatPoolCheckpointStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.attempts = attempts
            self.minimum = minimum
            self.attributes = attributes
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

        func canMoveTo(_ next: FallbackFloatPoolCheckpointStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == FallbackFloatPoolCheckpointStatus.done || next == FallbackFloatPoolCheckpointStatus.failed
            case .done:
                return next == FallbackFloatPoolCheckpointStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackFloatPoolCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback float pool checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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

        func netVolume() -> Double {
            return (minimum * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> FallbackFloatPoolCheckpoint {
            return FallbackFloatPoolCheckpoint(
                code: code,
                label: label,
                createdAt: createdAt,
                attempts: attempts,
                minimum: minimum,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback float pool checkpoint in status new.
    static func newFallbackFloatPoolCheckpoint(_ code: String, label: String) -> FallbackFloatPoolCheckpoint {
        return FallbackFloatPoolCheckpoint(
            code: code,
            label: label,
            createdAt: 0,
            attempts: 0,
            minimum: 0.0,
            attributes: [:],
            status: FallbackFloatPoolCheckpointStatus.new
        )
    }
}
