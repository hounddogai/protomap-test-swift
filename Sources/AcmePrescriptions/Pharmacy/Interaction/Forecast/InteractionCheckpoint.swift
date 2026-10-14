import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction checkpoint is in its life cycle.
    enum InteractionCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A interaction checkpoint as the interaction team keeps it.
    final class InteractionCheckpoint {
        var code: String
        var name: String
        var ward: String
        var pinned: Bool
        var weight: Double
        var facility: String
        var limit: Int
        var ceiling: Double
        var attempts: Int
        var quantity: Int
        var attributes: [String: String]
        var status: InteractionCheckpointStatus

        init(code: String, name: String, ward: String, pinned: Bool, weight: Double, facility: String, limit: Int, ceiling: Double, attempts: Int, quantity: Int, attributes: [String: String], status: InteractionCheckpointStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.pinned = pinned
            self.weight = weight
            self.facility = facility
            self.limit = limit
            self.ceiling = ceiling
            self.attempts = attempts
            self.quantity = quantity
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

        func canMoveTo(_ next: InteractionCheckpointStatus) -> Bool {
            switch status {
            case .new:
                return next == InteractionCheckpointStatus.running || next == InteractionCheckpointStatus.done
            case .queued:
                return next == InteractionCheckpointStatus.failed
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

        func moveTo(_ next: InteractionCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func netValue() -> Double {
            return ((Double(quantity) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionCheckpoint {
            return InteractionCheckpoint(
                code: code,
                name: name,
                ward: ward,
                pinned: pinned,
                weight: weight,
                facility: facility,
                limit: limit,
                ceiling: ceiling,
                attempts: attempts,
                quantity: quantity,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a interaction checkpoint in status new.
    static func newInteractionCheckpoint(_ code: String, name: String) -> InteractionCheckpoint {
        return InteractionCheckpoint(
            code: code,
            name: name,
            ward: "",
            pinned: false,
            weight: 0.0,
            facility: "",
            limit: 0,
            ceiling: 0.0,
            attempts: 0,
            quantity: 0,
            attributes: [:],
            status: InteractionCheckpointStatus.new
        )
    }
}
