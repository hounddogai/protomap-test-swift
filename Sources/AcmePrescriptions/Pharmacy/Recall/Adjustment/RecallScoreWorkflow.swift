import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall scores through their life cycle and keeps a journal of what it did.
    final class RecallScoreManager {
        var store: any RecallScoreStore
        var validator: RecallScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RecallScoreEngine

        init(store: any RecallScoreStore, validator: RecallScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RecallScoreEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallScoreStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallScoreStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall score \(code) not found")
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

    static func newRecallScoreManager(_ store: any RecallScoreStore, clock: any Kit.Clocks.Clock) -> RecallScoreManager {
        return RecallScoreManager(
            store: store,
            validator: defaultRecallScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultRecallScoreEngine()
        )
    }
}
