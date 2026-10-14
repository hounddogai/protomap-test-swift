import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves primary rounding scores through their life cycle and keeps a journal of what it did.
    final class PrimaryRoundingScoreService {
        var store: any PrimaryRoundingScoreStore
        var validator: PrimaryRoundingScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryRoundingScoreEngine

        init(store: any PrimaryRoundingScoreStore, validator: PrimaryRoundingScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryRoundingScoreEngine) {
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
                throw Kit.Failure("primary rounding score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryRoundingScoreStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary rounding score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryRoundingScoreStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary rounding score \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newPrimaryRoundingScoreService(_ store: any PrimaryRoundingScoreStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryRoundingScoreService {
        return PrimaryRoundingScoreService(
            store: store,
            validator: defaultPrimaryRoundingScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryRoundingScoreEngine(flags)
        )
    }
}
