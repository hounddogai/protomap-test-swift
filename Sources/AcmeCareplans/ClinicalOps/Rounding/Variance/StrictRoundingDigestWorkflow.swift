import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves strict rounding digests through their life cycle and keeps a journal of what it did.
    final class StrictRoundingDigestWorkflow {
        var store: any StrictRoundingDigestStore
        var validator: StrictRoundingDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictRoundingDigestEngine

        init(store: any StrictRoundingDigestStore, validator: StrictRoundingDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictRoundingDigestEngine) {
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
                throw Kit.Failure("strict rounding digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictRoundingDigestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict rounding digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictRoundingDigestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict rounding digest \(code) not found")
            }
            let result = engine.run(item)
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

    static func newStrictRoundingDigestWorkflow(_ store: any StrictRoundingDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictRoundingDigestWorkflow {
        return StrictRoundingDigestWorkflow(
            store: store,
            validator: defaultStrictRoundingDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictRoundingDigestEngine(flags)
        )
    }
}
