import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves manual census entries through their life cycle and keeps a journal of what it did.
    final class ManualCensusEntryService {
        var store: any ManualCensusEntryStore
        var validator: ManualCensusEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualCensusEntryEngine

        init(store: any ManualCensusEntryStore, validator: ManualCensusEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualCensusEntryEngine) {
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
                throw Kit.Failure("manual census entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualCensusEntryStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual census entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualCensusEntryStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual census entry \(code) not found")
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

    static func newManualCensusEntryService(_ store: any ManualCensusEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualCensusEntryService {
        return ManualCensusEntryService(
            store: store,
            validator: defaultManualCensusEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualCensusEntryEngine(flags)
        )
    }
}
