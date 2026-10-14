import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read overrides through their life cycle and keeps a journal of what it did.
    final class ReadOverrideManager {
        var store: any ReadOverrideStore
        var validator: ReadOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReadOverrideEngine

        init(store: any ReadOverrideStore, validator: ReadOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReadOverrideEngine) {
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
                throw Kit.Failure("read override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadOverrideStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadOverrideStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("read override \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newReadOverrideManager(_ store: any ReadOverrideStore, clock: any Kit.Clocks.Clock) -> ReadOverrideManager {
        return ReadOverrideManager(
            store: store,
            validator: defaultReadOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultReadOverrideEngine()
        )
    }
}
