import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves substitution entries through their life cycle and keeps a journal of what it did.
    final class SubstitutionEntryService {
        var store: any SubstitutionEntryStore
        var validator: SubstitutionEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SubstitutionEntryEngine

        init(store: any SubstitutionEntryStore, validator: SubstitutionEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SubstitutionEntryEngine) {
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
                throw Kit.Failure("substitution entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SubstitutionEntryStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SubstitutionEntryStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution entry \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newSubstitutionEntryService(_ store: any SubstitutionEntryStore, clock: any Kit.Clocks.Clock) -> SubstitutionEntryService {
        return SubstitutionEntryService(
            store: store,
            validator: defaultSubstitutionEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultSubstitutionEntryEngine()
        )
    }
}
