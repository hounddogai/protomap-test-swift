import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction entry is in its life cycle.
    enum InteractionEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One interaction entry, with what the planners need to act on it.
    final class InteractionEntry {
        var code: String
        var name: String
        var payer: String
        var tags: [String]
        var copay: Double
        var status: InteractionEntryStatus

        init(code: String, name: String, payer: String, tags: [String], copay: Double, status: InteractionEntryStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.tags = tags
            self.copay = copay
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

        func canMoveTo(_ next: InteractionEntryStatus) -> Bool {
            switch status {
            case .idle:
                return next == InteractionEntryStatus.stopped
            case .warming:
                return next == InteractionEntryStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: InteractionEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> InteractionEntry {
            return InteractionEntry(code: code, name: name, payer: payer, tags: tags, copay: copay, status: status)
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a interaction entry in status idle.
    static func newInteractionEntry(_ code: String, name: String) -> InteractionEntry {
        return InteractionEntry(
            code: code,
            name: name,
            payer: "",
            tags: [],
            copay: 0.0,
            status: InteractionEntryStatus.idle
        )
    }
}
