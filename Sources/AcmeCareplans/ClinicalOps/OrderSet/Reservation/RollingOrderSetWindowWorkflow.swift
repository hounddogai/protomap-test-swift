import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rolling order set windows through their life cycle and keeps a journal of what it did.
    final class RollingOrderSetWindowCoordinator {
        var store: any RollingOrderSetWindowStore
        var validator: RollingOrderSetWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingOrderSetWindowEngine

        init(store: any RollingOrderSetWindowStore, validator: RollingOrderSetWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingOrderSetWindowEngine) {
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
                throw Kit.Failure("rolling order set window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingOrderSetWindowStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling order set window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingOrderSetWindowStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling order set window \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRollingOrderSetWindowCoordinator(_ store: any RollingOrderSetWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingOrderSetWindowCoordinator {
        return RollingOrderSetWindowCoordinator(
            store: store,
            validator: defaultRollingOrderSetWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingOrderSetWindowEngine(flags)
        )
    }
}
