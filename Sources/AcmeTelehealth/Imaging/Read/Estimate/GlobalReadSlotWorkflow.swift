import AcmePlatform
import Foundation

extension Imaging {
    /// Moves global read slots through their life cycle and keeps a journal of what it did.
    final class GlobalReadSlotCoordinator {
        var store: any GlobalReadSlotStore
        var validator: GlobalReadSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalReadSlotEngine

        init(store: any GlobalReadSlotStore, validator: GlobalReadSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalReadSlotEngine) {
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
                throw Kit.Failure("global read slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalReadSlotStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global read slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalReadSlotStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global read slot \(code) not found")
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

    static func newGlobalReadSlotCoordinator(_ store: any GlobalReadSlotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalReadSlotCoordinator {
        return GlobalReadSlotCoordinator(
            store: store,
            validator: defaultGlobalReadSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalReadSlotEngine(flags)
        )
    }
}
