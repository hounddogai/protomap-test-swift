import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure windows through their life cycle and keeps a journal of what it did.
    final class ClosureWindowManager {
        var store: any ClosureWindowStore
        var validator: ClosureWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ClosureWindowStore, validator: ClosureWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureWindowStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureWindowStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newClosureWindowManager(_ store: any ClosureWindowStore, clock: any Kit.Clocks.Clock) -> ClosureWindowManager {
        return ClosureWindowManager(
            store: store,
            validator: defaultClosureWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
