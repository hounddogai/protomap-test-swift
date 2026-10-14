import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction manifest is in its life cycle.
    enum InteractionManifestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a interaction manifest and its current status.
    final class InteractionManifest {
        var code: String
        var name: String
        var attempts: Int
        var tags: [String]
        var score: Double
        var facility: String
        var graceDays: Int
        var status: InteractionManifestStatus

        init(code: String, name: String, attempts: Int, tags: [String], score: Double, facility: String, graceDays: Int, status: InteractionManifestStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.tags = tags
            self.score = score
            self.facility = facility
            self.graceDays = graceDays
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

        func canMoveTo(_ next: InteractionManifestStatus) -> Bool {
            switch status {
            case .new:
                return next == InteractionManifestStatus.done
            case .queued:
                return next == InteractionManifestStatus.running
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: InteractionManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func adjustedExposure() -> Double {
            return ((Double(graceDays) + score) * 100).rounded() / 100
        }

        func copyValue() -> InteractionManifest {
            return InteractionManifest(
                code: code,
                name: name,
                attempts: attempts,
                tags: tags,
                score: score,
                facility: facility,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a interaction manifest in status new.
    static func newInteractionManifest(_ code: String, name: String) -> InteractionManifest {
        return InteractionManifest(
            code: code,
            name: name,
            attempts: 0,
            tags: [],
            score: 0.0,
            facility: "",
            graceDays: 0,
            status: InteractionManifestStatus.new
        )
    }
}
