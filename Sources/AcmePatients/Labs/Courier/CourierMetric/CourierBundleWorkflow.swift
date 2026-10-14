import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier bundles through their life cycle and keeps a journal of what it did.
    final class CourierBundleCoordinator {
        var store: any CourierBundleStore
        var validator: CourierBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CourierBundleStore, validator: CourierBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierBundleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierBundleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newCourierBundleCoordinator(_ store: any CourierBundleStore, clock: any Kit.Clocks.Clock) -> CourierBundleCoordinator {
        return CourierBundleCoordinator(
            store: store,
            validator: defaultCourierBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}
