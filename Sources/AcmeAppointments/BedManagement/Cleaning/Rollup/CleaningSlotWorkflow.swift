import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning slots through their life cycle and keeps a journal of what it did.
    final class CleaningSlotService {
        var store: any CleaningSlotStore
        var validator: CleaningSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CleaningSlotEngine

        init(store: any CleaningSlotStore, validator: CleaningSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CleaningSlotEngine) {
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
                throw Kit.Failure("cleaning slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningSlotStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningSlotStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning slot \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newCleaningSlotService(_ store: any CleaningSlotStore, clock: any Kit.Clocks.Clock) -> CleaningSlotService {
        return CleaningSlotService(
            store: store,
            validator: defaultCleaningSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultCleaningSlotEngine()
        )
    }
}
