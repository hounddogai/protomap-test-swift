import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves rolling interaction windows through their life cycle and keeps a journal of what it did.
    final class RollingInteractionWindowDesk {
        var store: any RollingInteractionWindowStore
        var validator: RollingInteractionWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingInteractionWindowStore, validator: RollingInteractionWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling interaction window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingInteractionWindowStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling interaction window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingInteractionWindowStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newRollingInteractionWindowDesk(_ store: any RollingInteractionWindowStore, clock: any Kit.Clocks.Clock) -> RollingInteractionWindowDesk {
        return RollingInteractionWindowDesk(
            store: store,
            validator: defaultRollingInteractionWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
