import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding targets through their life cycle and keeps a journal of what it did.
    final class RoundingTargetCoordinator {
        var store: any RoundingTargetStore
        var validator: RoundingTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RoundingTargetEngine

        init(store: any RoundingTargetStore, validator: RoundingTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RoundingTargetEngine) {
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
                throw Kit.Failure("rounding target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingTargetStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingTargetStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding target \(code) not found")
            }
            let result = engine.run(item)
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

    static func newRoundingTargetCoordinator(_ store: any RoundingTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RoundingTargetCoordinator {
        return RoundingTargetCoordinator(
            store: store,
            validator: defaultRoundingTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultRoundingTargetEngine(flags)
        )
    }
}
