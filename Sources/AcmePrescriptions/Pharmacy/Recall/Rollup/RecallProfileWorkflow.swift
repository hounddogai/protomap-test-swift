import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall profiles through their life cycle and keeps a journal of what it did.
    final class RecallProfileManager {
        var store: any RecallProfileStore
        var validator: RecallProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RecallProfileEngine

        init(store: any RecallProfileStore, validator: RecallProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RecallProfileEngine) {
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
                throw Kit.Failure("recall profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallProfileStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallProfileStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall profile \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRecallProfileManager(_ store: any RecallProfileStore, clock: any Kit.Clocks.Clock) -> RecallProfileManager {
        return RecallProfileManager(
            store: store,
            validator: defaultRecallProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultRecallProfileEngine()
        )
    }
}
