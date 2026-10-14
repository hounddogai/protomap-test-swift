import AcmePlatform
import Foundation

extension Imaging {
    /// Moves capped read preferences through their life cycle and keeps a journal of what it did.
    final class CappedReadPreferenceCoordinator {
        var store: any CappedReadPreferenceStore
        var validator: CappedReadPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedReadPreferenceEngine

        init(store: any CappedReadPreferenceStore, validator: CappedReadPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedReadPreferenceEngine) {
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
                throw Kit.Failure("capped read preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedReadPreferenceStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped read preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedReadPreferenceStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped read preference \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newCappedReadPreferenceCoordinator(_ store: any CappedReadPreferenceStore, clock: any Kit.Clocks.Clock) -> CappedReadPreferenceCoordinator {
        return CappedReadPreferenceCoordinator(
            store: store,
            validator: defaultCappedReadPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedReadPreferenceEngine()
        )
    }
}
