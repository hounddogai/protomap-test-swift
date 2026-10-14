import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure cycles through their life cycle and keeps a journal of what it did.
    final class DisclosureCycleDesk {
        var store: any DisclosureCycleStore
        var validator: DisclosureCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DisclosureCycleStore, validator: DisclosureCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("disclosure cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureCycleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureCycleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newDisclosureCycleDesk(_ store: any DisclosureCycleStore, clock: any Kit.Clocks.Clock) -> DisclosureCycleDesk {
        return DisclosureCycleDesk(
            store: store,
            validator: defaultDisclosureCycleValidator(),
            clock: clock,
            journal: []
        )
    }
}
