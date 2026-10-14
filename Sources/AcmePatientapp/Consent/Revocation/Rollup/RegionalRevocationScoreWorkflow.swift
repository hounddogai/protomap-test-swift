import AcmePlatform
import Foundation

extension Consent {
    /// Moves regional revocation scores through their life cycle and keeps a journal of what it did.
    final class RegionalRevocationScoreService {
        var store: any RegionalRevocationScoreStore
        var validator: RegionalRevocationScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalRevocationScoreEngine

        init(store: any RegionalRevocationScoreStore, validator: RegionalRevocationScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalRevocationScoreEngine) {
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
                throw Kit.Failure("regional revocation score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalRevocationScoreStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional revocation score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalRevocationScoreStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional revocation score \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newRegionalRevocationScoreService(_ store: any RegionalRevocationScoreStore, clock: any Kit.Clocks.Clock) -> RegionalRevocationScoreService {
        return RegionalRevocationScoreService(
            store: store,
            validator: defaultRegionalRevocationScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalRevocationScoreEngine()
        )
    }
}
