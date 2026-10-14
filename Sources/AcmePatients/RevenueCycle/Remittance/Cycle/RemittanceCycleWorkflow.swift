import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance cycles through their life cycle and keeps a journal of what it did.
    final class RemittanceCycleWorkflow {
        var store: any RemittanceCycleStore
        var validator: RemittanceCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceCycleEngine

        init(store: any RemittanceCycleStore, validator: RemittanceCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceCycleEngine) {
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
                throw Kit.Failure("remittance cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceCycleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceCycleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance cycle \(code) not found")
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

    static func newRemittanceCycleWorkflow(_ store: any RemittanceCycleStore, clock: any Kit.Clocks.Clock) -> RemittanceCycleWorkflow {
        return RemittanceCycleWorkflow(
            store: store,
            validator: defaultRemittanceCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceCycleEngine()
        )
    }
}
