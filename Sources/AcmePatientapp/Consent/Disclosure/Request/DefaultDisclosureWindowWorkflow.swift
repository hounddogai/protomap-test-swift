import AcmePlatform
import Foundation

extension Consent {
    /// Moves default disclosure windows through their life cycle and keeps a journal of what it did.
    final class DefaultDisclosureWindowManager {
        var store: any DefaultDisclosureWindowStore
        var validator: DefaultDisclosureWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultDisclosureWindowEngine

        init(store: any DefaultDisclosureWindowStore, validator: DefaultDisclosureWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultDisclosureWindowEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default disclosure window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultDisclosureWindowStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default disclosure window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultDisclosureWindowStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default disclosure window \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newDefaultDisclosureWindowManager(_ store: any DefaultDisclosureWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultDisclosureWindowManager {
        return DefaultDisclosureWindowManager(
            store: store,
            validator: defaultDefaultDisclosureWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultDisclosureWindowEngine(flags)
        )
    }
}
