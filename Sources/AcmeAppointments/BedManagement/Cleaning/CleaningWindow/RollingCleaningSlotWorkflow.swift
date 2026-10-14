import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves rolling cleaning slots through their life cycle and keeps a journal of what it did.
    final class RollingCleaningSlotService {
        var store: any RollingCleaningSlotStore
        var validator: RollingCleaningSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingCleaningSlotEngine

        init(store: any RollingCleaningSlotStore, validator: RollingCleaningSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingCleaningSlotEngine) {
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
                throw Kit.Failure("rolling cleaning slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingCleaningSlotStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling cleaning slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingCleaningSlotStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling cleaning slot \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newRollingCleaningSlotService(_ store: any RollingCleaningSlotStore, clock: any Kit.Clocks.Clock) -> RollingCleaningSlotService {
        return RollingCleaningSlotService(
            store: store,
            validator: defaultRollingCleaningSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingCleaningSlotEngine()
        )
    }
}
