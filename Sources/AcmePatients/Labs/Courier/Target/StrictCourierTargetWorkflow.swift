import AcmePlatform
import Foundation

extension Labs {
    /// Moves strict courier targets through their life cycle and keeps a journal of what it did.
    final class StrictCourierTargetCoordinator {
        var store: any StrictCourierTargetStore
        var validator: StrictCourierTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictCourierTargetEngine

        init(store: any StrictCourierTargetStore, validator: StrictCourierTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictCourierTargetEngine) {
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
                throw Kit.Failure("strict courier target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictCourierTargetStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict courier target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictCourierTargetStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict courier target \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newStrictCourierTargetCoordinator(_ store: any StrictCourierTargetStore, clock: any Kit.Clocks.Clock) -> StrictCourierTargetCoordinator {
        return StrictCourierTargetCoordinator(
            store: store,
            validator: defaultStrictCourierTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictCourierTargetEngine()
        )
    }
}
