import AcmePlatform
import Foundation

extension Consent {
    /// Moves strict witness audits through their life cycle and keeps a journal of what it did.
    final class StrictWitnessAuditService {
        var store: any StrictWitnessAuditStore
        var validator: StrictWitnessAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictWitnessAuditEngine

        init(store: any StrictWitnessAuditStore, validator: StrictWitnessAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictWitnessAuditEngine) {
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
                throw Kit.Failure("strict witness audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictWitnessAuditStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict witness audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictWitnessAuditStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict witness audit \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newStrictWitnessAuditService(_ store: any StrictWitnessAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictWitnessAuditService {
        return StrictWitnessAuditService(
            store: store,
            validator: defaultStrictWitnessAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictWitnessAuditEngine(flags)
        )
    }
}
