import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves pending order set groups through their life cycle and keeps a journal of what it did.
    final class PendingOrderSetGroupWorkflow {
        var store: any PendingOrderSetGroupStore
        var validator: PendingOrderSetGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingOrderSetGroupEngine

        init(store: any PendingOrderSetGroupStore, validator: PendingOrderSetGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingOrderSetGroupEngine) {
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
                throw Kit.Failure("pending order set group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingOrderSetGroupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending order set group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingOrderSetGroupStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending order set group \(code) not found")
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

    static func newPendingOrderSetGroupWorkflow(_ store: any PendingOrderSetGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingOrderSetGroupWorkflow {
        return PendingOrderSetGroupWorkflow(
            store: store,
            validator: defaultPendingOrderSetGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingOrderSetGroupEngine(flags)
        )
    }
}
