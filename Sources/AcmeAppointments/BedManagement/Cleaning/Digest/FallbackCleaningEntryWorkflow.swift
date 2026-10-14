import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves fallback cleaning entries through their life cycle and keeps a journal of what it did.
    final class FallbackCleaningEntryService {
        var store: any FallbackCleaningEntryStore
        var validator: FallbackCleaningEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackCleaningEntryEngine

        init(store: any FallbackCleaningEntryStore, validator: FallbackCleaningEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackCleaningEntryEngine) {
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
                throw Kit.Failure("fallback cleaning entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackCleaningEntryStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback cleaning entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackCleaningEntryStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback cleaning entry \(code) not found")
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

    static func newFallbackCleaningEntryService(_ store: any FallbackCleaningEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackCleaningEntryService {
        return FallbackCleaningEntryService(
            store: store,
            validator: defaultFallbackCleaningEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackCleaningEntryEngine(flags)
        )
    }
}
