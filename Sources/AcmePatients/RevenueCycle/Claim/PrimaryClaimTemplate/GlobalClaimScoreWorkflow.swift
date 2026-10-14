import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves global claim scores through their life cycle and keeps a journal of what it did.
    final class GlobalClaimScoreManager {
        var store: any GlobalClaimScoreStore
        var validator: GlobalClaimScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalClaimScoreEngine

        init(store: any GlobalClaimScoreStore, validator: GlobalClaimScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalClaimScoreEngine) {
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
                throw Kit.Failure("global claim score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalClaimScoreStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global claim score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalClaimScoreStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global claim score \(code) not found")
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

    static func newGlobalClaimScoreManager(_ store: any GlobalClaimScoreStore, clock: any Kit.Clocks.Clock) -> GlobalClaimScoreManager {
        return GlobalClaimScoreManager(
            store: store,
            validator: defaultGlobalClaimScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalClaimScoreEngine()
        )
    }
}
