import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure preferences through their life cycle and keeps a journal of what it did.
    final class ClosurePreferenceCoordinator {
        var store: any ClosurePreferenceStore
        var validator: ClosurePreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosurePreferenceEngine

        init(store: any ClosurePreferenceStore, validator: ClosurePreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosurePreferenceEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosurePreferenceStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosurePreferenceStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure preference \(code) not found")
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

    static func newClosurePreferenceCoordinator(_ store: any ClosurePreferenceStore, clock: any Kit.Clocks.Clock) -> ClosurePreferenceCoordinator {
        return ClosurePreferenceCoordinator(
            store: store,
            validator: defaultClosurePreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosurePreferenceEngine()
        )
    }
}
