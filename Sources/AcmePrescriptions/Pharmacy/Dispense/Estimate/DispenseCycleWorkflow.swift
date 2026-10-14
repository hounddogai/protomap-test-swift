import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense cycles through their life cycle and keeps a journal of what it did.
    final class DispenseCycleDesk {
        var store: any DispenseCycleStore
        var validator: DispenseCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DispenseCycleEngine

        init(store: any DispenseCycleStore, validator: DispenseCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DispenseCycleEngine) {
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
                throw Kit.Failure("dispense cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispenseCycleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispenseCycleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense cycle \(code) not found")
            }
            let result = engine.run(item)
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

    static func newDispenseCycleDesk(_ store: any DispenseCycleStore, clock: any Kit.Clocks.Clock) -> DispenseCycleDesk {
        return DispenseCycleDesk(
            store: store,
            validator: defaultDispenseCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultDispenseCycleEngine()
        )
    }
}
