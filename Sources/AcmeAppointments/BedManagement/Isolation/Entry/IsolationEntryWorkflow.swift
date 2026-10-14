import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves isolation entries through their life cycle and keeps a journal of what it did.
    final class IsolationEntryManager {
        var store: any IsolationEntryStore
        var validator: IsolationEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: IsolationEntryEngine

        init(store: any IsolationEntryStore, validator: IsolationEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: IsolationEntryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(IsolationEntryStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(IsolationEntryStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation entry \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newIsolationEntryManager(_ store: any IsolationEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> IsolationEntryManager {
        return IsolationEntryManager(
            store: store,
            validator: defaultIsolationEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultIsolationEntryEngine(flags)
        )
    }
}
