import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves strict authorization windows through their life cycle and keeps a journal of what it did.
    final class StrictAuthorizationWindowCoordinator {
        var store: any StrictAuthorizationWindowStore
        var validator: StrictAuthorizationWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictAuthorizationWindowStore, validator: StrictAuthorizationWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict authorization window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictAuthorizationWindowStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict authorization window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictAuthorizationWindowStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newStrictAuthorizationWindowCoordinator(_ store: any StrictAuthorizationWindowStore, clock: any Kit.Clocks.Clock) -> StrictAuthorizationWindowCoordinator {
        return StrictAuthorizationWindowCoordinator(
            store: store,
            validator: defaultStrictAuthorizationWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
