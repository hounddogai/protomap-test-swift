import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves capped dispense checkpoints through their life cycle and keeps a journal of what it did.
    final class CappedDispenseCheckpointService {
        var store: any CappedDispenseCheckpointStore
        var validator: CappedDispenseCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedDispenseCheckpointEngine

        init(store: any CappedDispenseCheckpointStore, validator: CappedDispenseCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedDispenseCheckpointEngine) {
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
                throw Kit.Failure("capped dispense checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedDispenseCheckpointStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped dispense checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedDispenseCheckpointStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped dispense checkpoint \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCappedDispenseCheckpointService(_ store: any CappedDispenseCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedDispenseCheckpointService {
        return CappedDispenseCheckpointService(
            store: store,
            validator: defaultCappedDispenseCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedDispenseCheckpointEngine(flags)
        )
    }
}
