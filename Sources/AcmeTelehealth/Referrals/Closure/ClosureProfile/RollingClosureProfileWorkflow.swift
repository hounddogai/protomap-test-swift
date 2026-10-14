import AcmePlatform
import Foundation

extension Referrals {
    /// Moves rolling closure profiles through their life cycle and keeps a journal of what it did.
    final class RollingClosureProfileCoordinator {
        var store: any RollingClosureProfileStore
        var validator: RollingClosureProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingClosureProfileEngine

        init(store: any RollingClosureProfileStore, validator: RollingClosureProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingClosureProfileEngine) {
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
                throw Kit.Failure("rolling closure profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingClosureProfileStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling closure profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingClosureProfileStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling closure profile \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newRollingClosureProfileCoordinator(_ store: any RollingClosureProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingClosureProfileCoordinator {
        return RollingClosureProfileCoordinator(
            store: store,
            validator: defaultRollingClosureProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingClosureProfileEngine(flags)
        )
    }
}
