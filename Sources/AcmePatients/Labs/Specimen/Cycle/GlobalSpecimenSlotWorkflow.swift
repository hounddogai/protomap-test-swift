import AcmePlatform
import Foundation

extension Labs {
    /// Moves global specimen slots through their life cycle and keeps a journal of what it did.
    final class GlobalSpecimenSlotCoordinator {
        var store: any GlobalSpecimenSlotStore
        var validator: GlobalSpecimenSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalSpecimenSlotEngine

        init(store: any GlobalSpecimenSlotStore, validator: GlobalSpecimenSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalSpecimenSlotEngine) {
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
                throw Kit.Failure("global specimen slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalSpecimenSlotStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global specimen slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalSpecimenSlotStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global specimen slot \(code) not found")
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

    static func newGlobalSpecimenSlotCoordinator(_ store: any GlobalSpecimenSlotStore, clock: any Kit.Clocks.Clock) -> GlobalSpecimenSlotCoordinator {
        return GlobalSpecimenSlotCoordinator(
            store: store,
            validator: defaultGlobalSpecimenSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalSpecimenSlotEngine()
        )
    }
}
