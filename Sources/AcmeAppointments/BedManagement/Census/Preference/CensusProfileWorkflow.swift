import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves census profiles through their life cycle and keeps a journal of what it did.
    final class CensusProfileWorkflow {
        var store: any CensusProfileStore
        var validator: CensusProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CensusProfileEngine

        init(store: any CensusProfileStore, validator: CensusProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CensusProfileEngine) {
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
                throw Kit.Failure("census profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CensusProfileStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("census profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CensusProfileStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("census profile \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newCensusProfileWorkflow(_ store: any CensusProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CensusProfileWorkflow {
        return CensusProfileWorkflow(
            store: store,
            validator: defaultCensusProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultCensusProfileEngine(flags)
        )
    }
}
