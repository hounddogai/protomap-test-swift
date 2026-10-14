import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves substitution exceptions through their life cycle and keeps a journal of what it did.
    final class SubstitutionExceptionDesk {
        var store: any SubstitutionExceptionStore
        var validator: SubstitutionExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SubstitutionExceptionEngine

        init(store: any SubstitutionExceptionStore, validator: SubstitutionExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SubstitutionExceptionEngine) {
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
                throw Kit.Failure("substitution exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SubstitutionExceptionStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SubstitutionExceptionStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution exception \(code) not found")
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

    static func newSubstitutionExceptionDesk(_ store: any SubstitutionExceptionStore, clock: any Kit.Clocks.Clock) -> SubstitutionExceptionDesk {
        return SubstitutionExceptionDesk(
            store: store,
            validator: defaultSubstitutionExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultSubstitutionExceptionEngine()
        )
    }
}
