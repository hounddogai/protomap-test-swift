import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist slots through their life cycle and keeps a journal of what it did.
    final class WorklistSlotCoordinator {
        var store: any WorklistSlotStore
        var validator: WorklistSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistSlotEngine

        init(store: any WorklistSlotStore, validator: WorklistSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistSlotEngine) {
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
                throw Kit.Failure("worklist slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistSlotStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistSlotStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist slot \(code) not found")
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

    static func newWorklistSlotCoordinator(_ store: any WorklistSlotStore, clock: any Kit.Clocks.Clock) -> WorklistSlotCoordinator {
        return WorklistSlotCoordinator(
            store: store,
            validator: defaultWorklistSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistSlotEngine()
        )
    }
}
